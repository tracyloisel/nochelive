class StudyRunsController < ApplicationController
  include StudyIdentity

  FINISHERS_PAGE_SIZE = 100

  def create
    unit = StudyUnit.find(params[:study_unit_id])
    quiz = unit.published_quiz or raise ActiveRecord::RecordNotFound
    run = study_runs_for_identity.open.find_or_create_by!(study_quiz_version: quiz) do |record|
      record.device_digest = street_device_digest
      record.person = current_street_person
      record.opened_at = Time.current
      record.asked_at = Time.current
    end
    redirect_to study_run_path(run)
  end

  def show
    remember_device
    load_study_run
    @run.update_column(:asked_at, Time.current) if !@run.completed? && @run.asked_at.nil?
    @question = @run.question unless @run.completed?
    @answer = @run.current_answer unless @run.completed?
    if @run.completed?
      prompt_context = session.delete(:push_prompt_context)
      if prompt_context == "study_completed" && @run.person
        eligibility = Notifications::PromptEligibility.call(
          person: @run.person, device_token: device_token,
          category: "verses", context: prompt_context
        )
        @push_prompt = { category: "verses", context: prompt_context } if eligibility.eligible
      end
      finisher_ids = StudyRun.completed
        .where(study_quiz_version_id: @run.study_unit.study_quiz_versions.select(:id))
        .where.not(person_id: nil)
        .select(:person_id)
      finishers = Person.where(id: finisher_ids)
      @finishers_total = finishers.count
      @finishers_pages = [ (@finishers_total.to_f / FINISHERS_PAGE_SIZE).ceil, 1 ].max
      @finishers_page = params.fetch(:finishers_page, 1).to_i.clamp(1, @finishers_pages)
      stake_name = @run.person&.ward&.stake_name.presence
      @current_stake_name = stake_name
      current_priority = Arel::Nodes::Case.new
        .when(Person.arel_table[:id].eq(@run.person_id))
        .then(0)
        .else(1)
      priority = if stake_name
        quoted_stake = ActiveRecord::Base.connection.quote(stake_name)
        Arel.sql("CASE WHEN wards.stake_name = #{quoted_stake} THEN 0 ELSE 1 END")
      else
        Arel.sql("CASE WHEN wards.id IS NULL THEN 1 ELSE 0 END")
      end
      @finishers = finishers.left_joins(:ward)
        .includes(:ward)
        .order(current_priority, priority, "wards.name ASC", "people.given_name ASC", "people.family_name ASC", "people.id ASC")
        .offset((@finishers_page - 1) * FINISHERS_PAGE_SIZE)
        .limit(FINISHERS_PAGE_SIZE)
      @stake_finishers, @other_finishers = @finishers.partition do |person|
        stake_name.present? && person.ward&.stake_name == stake_name
      end
      @same_stake_finishers_total = stake_name.present? ? finishers.joins(:ward).where(wards: { stake_name: }).count : 0
      @more_finishers = @finishers_page < @finishers_pages

      program = @run.study_unit.study_program
      @completed_week_count = study_runs_for_identity.completed
        .joins(study_quiz_version: :study_unit)
        .where(study_units: { study_program_id: program.id })
        .distinct.count("study_units.id")
      @program_week_count = program.study_units.weeks.count
    end
  rescue ActiveRecord::RecordNotFound
    run = study_runs_for_identity.open.order(updated_at: :desc).first

    redirect_to(run ? study_run_path(run) : study_program_path)
  end
end
