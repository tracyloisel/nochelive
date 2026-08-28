class IdentityTransfersController < ApplicationController
  SOURCE_HOST = "nochelive.onrender.com"
  TARGET_HOST = "nochelive.com"
  SIGNED_COOKIE_LIFETIMES = {
    "noche_device" => 1.year,
    "noche_ward" => 1.year,
    "noche_street_person" => 1.year,
    "noche_street_guest" => 1.year
  }.freeze

  before_action :disable_storage

  def create
    return head :not_found unless request.host == SOURCE_HOST

    IdentityTransfer.prune_expired!
    token = IdentityTransfer.issue!(transfer_payload)
    redirect_to claim_url(token), allow_other_host: true, status: :see_other
  end

  def claim
    return head :not_found unless request.host == TARGET_HOST

    payload = IdentityTransfer.fetch!(params[:token])
    source_person = transferred_person(payload)
    target_person = current_street_person

    if profile_conflict?(source_person, target_person)
      prepare_conflict(source_person:, target_person:, token: params[:token])
      render :claim
      return
    end

    IdentityTransfer.consume!(params[:token])
    finish_without_conflict(payload:, source_person:, target_person:)
  rescue IdentityTransfer::InvalidToken
    redirect_to_target alert: I18n.t("identity_migration.expired")
  end

  def merge
    return head :not_found unless request.host == TARGET_HOST

    payload = IdentityTransfer.fetch!(params[:token])
    source_person = transferred_person(payload)
    target_person = current_street_person

    unless profile_conflict?(source_person, target_person)
      IdentityTransfer.consume!(params[:token])
      finish_without_conflict(payload:, source_person:, target_person:)
      return
    end

    unless mergeable_profiles?(source_person, target_person)
      prepare_conflict(source_person:, target_person:, token: params[:token])
      @merge_error = I18n.t("identity_migration.cannot_merge")
      render :claim, status: :unprocessable_entity
      return
    end

    target_device = cookies.signed[:noche_device]
    keeper, duplicate = [ source_person, target_person ].sort_by { |person| [ person.created_at, person.id ] }

    ApplicationRecord.transaction do
      IdentityTransfer.consume!(params[:token])
      People::Merge.call(keeper:, source: duplicate)
    end

    remember_device(target_device)
    remember_street_person(keeper)
    remember_ward(keeper.ward)
    restore_locale(payload) if cookies[Locale::COOKIE].blank?
    redirect_to_target notice: I18n.t("identity_migration.merged")
  rescue IdentityTransfer::InvalidToken
    redirect_to_target alert: I18n.t("identity_migration.expired")
  rescue People::Error => error
    payload = IdentityTransfer.fetch!(params[:token])
    prepare_conflict(
      source_person: transferred_person(payload),
      target_person: current_street_person,
      token: params[:token]
    )
    @merge_error = error.message
    render :claim, status: :unprocessable_entity
  end

  private

    def transfer_payload
      signed = SIGNED_COOKIE_LIFETIMES.keys.index_with { |name| cookies.signed[name] }.compact
      {
        "signed" => signed,
        "locale" => cookies[Locale::COOKIE].presence
      }.compact
    end

    def restore_cookies(payload)
      payload.fetch("signed", {}).each do |name, value|
        next unless SIGNED_COOKIE_LIFETIMES.key?(name)

        cookies.signed[name] = cookie_options(value, SIGNED_COOKIE_LIFETIMES.fetch(name))
      end

      restore_locale(payload)
    end

    def restore_locale(payload)
      locale = payload["locale"]
      cookies[Locale::COOKIE] = cookie_options(Locale.cast(locale), 1.year) if locale.present?
    end

    def transferred_person(payload)
      signed = payload.fetch("signed", {})
      person_id = signed["noche_street_person"]
      source_device = signed["noche_device"]
      return if person_id.blank? || source_device.blank?

      Person.joins(:person_devices).find_by(
        id: person_id,
        person_devices: { device_token: source_device }
      )
    end

    def profile_conflict?(source_person, target_person)
      source_person.present? && target_person.present? && source_person.id != target_person.id
    end

    def mergeable_profiles?(source_person, target_person)
      source_person.ward_id.present? &&
        source_person.ward_id == target_person.ward_id &&
        source_person.given_name_key == target_person.given_name_key
    end

    def prepare_conflict(source_person:, target_person:, token:)
      @source_person = source_person
      @target_person = target_person
      @token = token
      @mergeable = mergeable_profiles?(source_person, target_person)
      @source_score = profile_score(source_person)
      @target_score = profile_score(target_person)
    end

    def profile_score(person)
      return 0 unless person&.ward

      Quizzes::Leaderboard.pack_best_totals(ward: person.ward)[person.id].to_i
    end

    def finish_without_conflict(payload:, source_person:, target_person:)
      if target_person.present?
        remember_street_person(target_person)
        remember_ward(target_person.ward) if target_person.ward
        restore_locale(payload) if cookies[Locale::COOKIE].blank?
      else
        restore_cookies(payload)
      end

      redirect_to_target
    end

    def redirect_to_target(notice: nil, alert: nil)
      redirect_to root_url(host: TARGET_HOST, protocol: "https"),
        status: :see_other,
        notice:,
        alert:
    end

    def cookie_options(value, lifetime)
      {
        value: value,
        expires: lifetime.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
    end

    def claim_url(token)
      identity_transfer_claim_url(
        host: TARGET_HOST,
        protocol: "https",
        token: token
      )
    end

    def disable_storage
      response.headers["Cache-Control"] = "no-store"
      response.headers["Referrer-Policy"] = "no-referrer"
    end
end
