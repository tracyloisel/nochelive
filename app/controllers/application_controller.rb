class ApplicationController < ActionController::Base
  include Identity
  include SeoMetadata
  allow_browser versions: :modern unless Rails.env.test?
  before_action :load_night_for_locale
  before_action :acknowledge_notification_open
  before_action :redirect_to_canonical_host
  around_action :use_locale

  private

    def acknowledge_notification_open
      delivery_id = params[:nl_delivery]
      return if delivery_id.blank? || !Notifications::Feature.enabled?

      delivery = current_street_person&.notification_deliveries&.find_by(id: delivery_id)
      Notifications::AcknowledgeOpen.call(delivery:, person: current_street_person, path: request.path) if delivery
    end

    def load_night_for_locale
      code = params[:session_code]
      return if code.blank? || @night

      @night = GameSession.find_by_code(code)
    end

    def redirect_to_canonical_host
      return unless Rails.env.production? && request.get?
      return if request.path == "/up"
      return if controller_name == "identity_transfers"
      return if request.host == IdentityTransfersController::SOURCE_HOST && cookies.signed[:noche_device].present?

      canonical_host = Rails.configuration.x.app_host.to_s.split(":").first
      return if canonical_host.blank? || request.host == canonical_host

      redirect_to request.url.sub(%r{\Ahttps?://[^/]+}, "https://#{canonical_host}"),
        status: :moved_permanently, allow_other_host: true
    end

    def use_locale(&block)
      I18n.with_locale(current_locale, &block)
    end
end
