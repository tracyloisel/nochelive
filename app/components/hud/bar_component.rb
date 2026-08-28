module Hud
  class BarComponent < ViewComponent::Base
    THEMES = %w[celestial-light celestial-dark].freeze

    def self.normalize_theme(value)
      candidate = value.to_s.tr("_", "-")
      candidate = "celestial-#{candidate}" if %w[light dark].include?(candidate)
      THEMES.include?(candidate) ? candidate : "celestial-light"
    end

    delegate :picto, :avatar_mark, :rank_name, :t, :link_to, :number_with_delimiter, to: :helpers

    def initialize(bar:, theme: "celestial-light")
      @bar = bar
      @theme = self.class.normalize_theme(theme)
    end

    attr_reader :bar, :theme

    def guest? = bar.guest?
    def quiz? = bar.quiz?

    def who_path
      guest? && !quiz? ? helpers.street_profile_path(fresh: 1) : helpers.root_path
    end

    def aria_label
      if guest?
        t("hub.guest_invite")
      elsif quiz?
        t("chrome.points", score: bar.score)
      else
        bar.name
      end
    end
  end
end
