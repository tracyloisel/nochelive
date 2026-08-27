class WardProfilesController < ApplicationController
  def show
    @ward = Wards::Enter.call(code: params[:code])
    remember_ward(@ward)
    @live_night = @ward.live_night
    @nights = @ward.game_sessions.includes(:missionaries, :players, teams: :players).order(starts_at: :desc).to_a
    @featured_night = @nights.select(&:live?).min_by(&:starts_at)
    @upcoming_nights = @nights.select { |night| night.live? && night != @featured_night }.sort_by(&:starts_at)
    @past_nights = @nights.select(&:finished?).sort_by(&:starts_at).reverse
    @last_finished_night = @past_nights.first
    @online_people = @ward.people
      .joins(:person_devices)
      .merge(PersonDevice.live)
      .distinct
      .order(:given_name)
      .limit(4)
      .to_a
    @online_count = @ward.people.joins(:person_devices).merge(PersonDevice.live).distinct.count
    @study_week = StudyProgram.order(year: :desc).first&.current_week
    @study_community = Studies::Community.call(ward: @ward, week: @study_week)
    @study_run = if @study_week
      StudyRun.joins(:study_quiz_version).where(
        study_quiz_versions: { study_unit_id: @study_week.id },
        device_digest: street_device_digest,
        person_id: current_street_person&.id
      ).order(updated_at: :desc).first
    end
    @study_progress = @study_run ? @study_run.study_answers.count : 0
    person = current_street_person
    person = nil unless person&.ward_id == @ward.id
    @board = Quizzes::Leaderboard.call(
      ward: @ward,
      person:,
      limit: Quizzes::Leaderboard::LIMIT_MINI
    )
  rescue People::Error
    redirect_to root_path, alert: I18n.t("errors.people.ward_missing")
  end
end
