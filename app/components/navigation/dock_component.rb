module Navigation
  class DockComponent < ViewComponent::Base
    delegate :picto, :t, to: :helpers

    Item = Data.define(:key, :path, :icon, :label_key)

    def initialize(active: :home)
      @active = active&.to_sym
    end

    attr_reader :active

    def items
      [
        Item.new(key: :home, path: helpers.root_path, icon: "meetinghouse", label_key: "hub.nav_home"),
        Item.new(key: :adventure, path: helpers.street_map_path, icon: "compass", label_key: "hub.nav_adventure"),
        Item.new(key: :word, path: helpers.study_program_path, icon: "scripture-book", label_key: "hub.nav_word"),
        Item.new(key: :church, path: helpers.church_path, icon: "church", label_key: "hub.nav_church"),
        Item.new(key: :profile, path: helpers.street_profile_path(edit: 1), icon: "person", label_key: "hub.nav_profile")
      ]
    end

    def item_class(item)
      [ "navigation-dock__item", ("is-active" if active == item.key) ].compact
    end

    def item_aria(item)
      { current: ("page" if active == item.key) }.compact
    end
  end
end
