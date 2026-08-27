module Hud
  class BarComponent < ViewComponent::Base
    delegate :picto, :avatar_mark, :rank_name, :t, :link_to, :number_with_delimiter, to: :helpers

    def initialize(bar:)
      @bar = bar
    end

    attr_reader :bar

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
