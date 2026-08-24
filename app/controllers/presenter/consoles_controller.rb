module Presenter
  class ConsolesController < ApplicationController
    before_action :set_night, :require_presenter

    def show
      @round = @night.current_round_run
    end
  end
end
