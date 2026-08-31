module StudyIdentity
  extend ActiveSupport::Concern

  private

    def load_study_run
      @run = study_runs_for_identity.find(params[:id] || params[:study_run_id])
    end

    def study_runs_for_identity
      return current_street_person.study_runs if current_street_person

      StudyRun.where(device_digest: street_device_digest, person_id: nil)
    end
end
