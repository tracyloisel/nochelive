class StreetProfileMergesController < ApplicationController
  def create
    source = current_street_person
    unless source&.ward
      redirect_to street_profile_path, alert: I18n.t("flashes.profile_required")
      return
    end

    candidate = source.ward.people.find_by(id: params[:person_id])
    raise People::Error.new(:missing, I18n.t("errors.people.missing")) unless candidate
    unless candidate.given_name_key == source.given_name_key
      raise People::Error.new(:merge_name, I18n.t("errors.people.merge_name"))
    end

    ApplicationRecord.transaction do
      claim_candidate!(candidate) unless candidate.person_devices.exists?(device_token: device_token)
      keeper, source = [ source, candidate ].sort_by { |person| [ person.created_at, person.id ] }
      People::Merge.call(keeper:, source:)
      @merged_person = keeper
    end
    remember_street_person(@merged_person)
    remember_ward(@merged_person.ward)
    redirect_to street_profile_path(edit: 1), notice: I18n.t("flashes.profile_merged", name: @merged_person.given_name)
  rescue People::Error => error
    redirect_to street_profile_path(edit: 1), alert: error.message
  end

  private

    def claim_candidate!(candidate)
      if candidate.favorite_year.blank?
        raise People::Error.new(:merge_unverifiable, I18n.t("errors.people.merge_unverifiable"))
      end

      People::Claim.call(
        ward: candidate.ward,
        person: candidate,
        favorite_year: params[:favorite_year],
        device_token: device_token
      )
    end
end
