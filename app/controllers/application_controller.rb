class ApplicationController < ActionController::Base
  include Identity
  allow_browser versions: :modern unless Rails.env.test?
end
