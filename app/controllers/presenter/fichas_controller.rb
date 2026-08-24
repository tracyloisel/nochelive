module Presenter
  class FichasController < ApplicationController
    include FichaDesk

    before_action :set_night, :require_presenter, :set_ward

    def index
      super
      render "fichas/index"
    end

    def show
      super
      render "fichas/show" unless performed?
    end

    private

      def set_ward
        @ward = @night.ward
      end
  end
end
