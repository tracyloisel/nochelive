class FichasController < ApplicationController
  include FichaDesk

  before_action :require_ward_admin, :set_ward

  private

    def set_ward
      @ward = managed_ward
      @night = nil
    end
end
