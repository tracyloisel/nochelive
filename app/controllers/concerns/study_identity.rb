module StudyIdentity
  extend ActiveSupport::Concern

  private

    def load_study_run
      @run = StudyRun.find_by!(
        id: params[:id] || params[:study_run_id],
        device_digest: street_device_digest,
        person_id: current_street_person&.id
      )
    end

    def current_study_program
      StudyProgram.order(year: :desc).first
    end
end
