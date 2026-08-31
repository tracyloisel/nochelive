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
    @ward_display_name = params[:slug].present? ? t("seo.ward.heading", city: @ward.city.presence || @ward.name) : @ward.name
    live_nights = @ward.game_sessions.live
    @live_nights = live_nights.order(:starts_at, :id).limit(8).to_a
    @featured_night = @live_nights.first
    remaining_live = @featured_night ? live_nights.where.not(id: @featured_night.id) : live_nights
    @upcoming_nights_count = remaining_live.count
    @upcoming_nights = remaining_live.order(:starts_at, :id).limit(3).to_a
    @rama_events = Hubs::RamaEvents.call(ward: @ward, at: Time.current, limit: 4)
    @featured_participants_count = @featured_night&.players&.count.to_i
    online_ids = Presences::Registry.online_person_ids(ward_id: @ward.id)
    @online_people = @ward.people
      .where(id: online_ids)
      .order(:given_name)
      .limit(4)
      .to_a
    @online_count = online_ids.size
    person = current_street_person
    person = nil unless person&.ward_id == @ward.id
    @study_week = StudyUnit
      .joins(:study_program)
      .where(study_programs: { status: "published" }, study_units: { kind: "week", status: "published" })
      .where("study_units.starts_on <= ? AND study_units.ends_on >= ?", Date.current, Date.current)
      .order(Arel.sql("study_programs.year DESC"), :position, :id)
      .first
    @study_community = Studies::Community.call(ward: @ward, week: @study_week)
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
    @board = Quizzes::Leaderboard.call(
      ward: @ward,
      person:,
      limit: Quizzes::Leaderboard::LIMIT_MINI
    )
  rescue People::Error
    redirect_to root_path, alert: I18n.t("errors.people.ward_missing")
  end

  private

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
