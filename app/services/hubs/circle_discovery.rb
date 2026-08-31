module Hubs
  # The Hub may invite a signed-in member into the Circle, but it never turns
  # a member post into promotional copy. This card is a product doorway only:
  # its availability follows the ward's existing read policy and its artwork
  # comes from the approved Circle manifest.
  class CircleDiscovery
    Card = Struct.new(:state, :path, :artwork, keyword_init: true)

    def self.call(person:, ward:, theme:)
      new(person:, ward:, theme:).call
    end

    def initialize(person:, ward:, theme:)
      @person = person
      @ward = ward
      @theme = theme.to_s
      @routes = Rails.application.routes.url_helpers
    end

    def call
      return unless @person && @ward
      return unless @person.ward_id == @ward.id
      return unless @ward.scripture_circle_readable?

      mode = %w[light dark].include?(@theme) ? @theme : "dark"
      Card.new(
        state: @ward.scripture_circle_mode.to_sym,
        path: @routes.scripture_circle_path,
        artwork: "scripture_circle.backdrop.#{mode}"
      )
    end
  end
end
