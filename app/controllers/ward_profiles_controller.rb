class WardProfilesController < ApplicationController
  def show
    @ward = params[:slug].present? ? Seo::WardPage.resolve(params[:slug]) : Wards::Enter.call(code: params[:code])
    raise People::Error.new(:missing, I18n.t("errors.people.ward_missing")) unless @ward

    if params[:slug].present? && !Seo::WardPage.valid_section?(params[:locale], params[:ward_section])
      redirect_to localized_ward_profile_path(**Seo::WardPage.path_options(@ward, I18n.locale)), status: :moved_permanently
      return
    end

    remember_ward(@ward)
    configure_ward_seo
    @featured_night = @ward.game_sessions.live.order(:starts_at, :id).first
    @featured_night_artwork = featured_night_artwork(@featured_night)
    person = current_street_person
    person = nil unless person&.ward_id == @ward.id
    @study_week = StudyUnit
      .joins(:study_program)
      .where(study_programs: { status: "published" }, study_units: { kind: "week", status: "published" })
      .where("study_units.starts_on <= ? AND study_units.ends_on >= ?", Date.current, Date.current)
      .order(Arel.sql("study_programs.year DESC"), :position, :id)
      .first
    study_quiz = @study_week&.published_quiz
    @expedition = if study_quiz&.expedition?
      Expeditions::Presentation.call(
        quiz: study_quiz,
        world: Quizzes::World.call(device_digest: street_device_digest, person_id: person&.id),
        person:,
        locale: I18n.locale
      )
    end
    @study_run = if @study_week && !@expedition
      StudyRun.joins(:study_quiz_version).where(
        study_quiz_versions: { study_unit_id: @study_week.id },
        device_digest: street_device_digest,
        person_id: current_street_person&.id
      ).order(updated_at: :desc).first
    end
    @study_progress = @expedition ? @expedition.completed_count : (@study_run ? @study_run.study_answers.count : 0)
    @ward_unit_kind = @ward.unit_kind.presence || inferred_unit_kind(@ward)
    @circle_visible = person.present? && @ward.scripture_circle_readable?
    @circle_writable = @circle_visible && @ward.scripture_circle_active?
    @circle_highlights = if @circle_visible
      ScriptureCircles::WardHighlights.call(
        ward: @ward,
        person:,
        locale: I18n.locale,
        references: @study_week&.scripture_refs
      )
    else
      []
    end
    @board = Quizzes::Leaderboard.call(
      ward: @ward,
      person:,
      limit: Quizzes::Leaderboard::LIMIT_MINI
    )
  rescue People::Error
    redirect_to root_path, alert: I18n.t("errors.people.ward_missing")
  end

  private

    def featured_night_artwork(night)
      return "scripture.library.daily.ps137.suspended-harps" if night&.quiz_pack_ids&.include?("exp_psalms_suspended_harps")

      night&.primary_quiz_pack&.questions&.first&.presentation&.[]("image").presence ||
        "scripture.library.daily.ps137.suspended-harps"
    end

    def inferred_unit_kind(ward)
      return "branch" if ward.name.to_s.match?(/\A(?:rama|ramo|branch|branche)\b/i)

      "ward"
    end

    def configure_ward_seo
      city = @ward.city.presence || @ward.name
      place = [ @ward.city, @ward.region, @ward.country_name ].compact_blank.join(", ")
      place = city if place.blank?
      canonical = localized_ward_profile_url(
        **Seo::WardPage.path_options(@ward, I18n.locale),
        host: Rails.configuration.x.app_host,
        protocol: "https"
      )
      alternates = I18n.available_locales.to_h do |locale|
        [ locale.to_s.downcase, localized_ward_profile_url(
          **Seo::WardPage.path_options(@ward, locale),
          host: Rails.configuration.x.app_host,
          protocol: "https"
        ) ]
      end
      alternates["x-default"] = alternates.fetch("es")

      index_for_search!(
        title: t("seo.ward.title", city:),
        description: t("seo.ward.description", city:, place:),
        canonical:,
        alternates:,
        structured_data: {
          "@context": "https://schema.org",
          "@type": "Church",
          name: t("seo.ward.structured_name", city:),
          alternateName: t("seo.ward.alternate_names", city:),
          url: canonical,
          address: {
            "@type": "PostalAddress",
            streetAddress: @ward.chapel_address,
            postalCode: @ward.postal_code,
            addressLocality: @ward.city,
            addressRegion: @ward.region,
            addressCountry: @ward.country_code
          }.compact
        }
      )
    end
end
