class StudyAdvancesController < ApplicationController
  include StudyIdentity

  def create
    load_study_run
    raise ActionController::BadRequest, "Answer first" unless @run.settled?

    if @run.position == 10
      @run.update!(status: "completed", completed_at: Time.current)
    else
      @run.increment!(:position)
    end
    redirect_to study_run_path(@run)
  end
end
