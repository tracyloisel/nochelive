module Navigation
  class DockComponent < ViewComponent::Base
    delegate :picto, :t, to: :helpers

    def initialize(active: :home, live: nil)
      @active = active&.to_sym
      @live = live
    end

    attr_reader :active, :live

    def item_class(item, *extra)
      [ "street-hub-nav-item", *extra, ("is-active" if active == item) ].compact
    end

  end
end
