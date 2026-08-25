class FichasController < ApplicationController
  include FichaDesk

  before_action :require_ward_presenter, :set_ward

  private

    def set_ward
      @ward = hosted_ward
      @night = nil
    end
end
