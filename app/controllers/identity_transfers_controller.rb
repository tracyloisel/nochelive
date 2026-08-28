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

    restore_cookies(IdentityTransfer.consume!(params[:token]))
    redirect_to root_url(host: TARGET_HOST, protocol: "https"), status: :see_other
  rescue IdentityTransfer::InvalidToken
    redirect_to root_url(host: TARGET_HOST, protocol: "https"), status: :see_other
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

      locale = payload["locale"]
      cookies[Locale::COOKIE] = cookie_options(Locale.cast(locale), 1.year) if locale.present?
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
