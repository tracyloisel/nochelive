class FichasController < ApplicationController
  include FichaDesk

  before_action :require_ward, :set_ward

  private

    def set_ward
      @ward = current_ward
      @night = nil
    end
end
