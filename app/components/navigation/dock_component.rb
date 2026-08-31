module Navigation
  class DockComponent < ViewComponent::Base
    delegate :picto, :t, to: :helpers

    Item = Data.define(:key, :path, :icon, :label_key)

    def initialize(active: :home)
      @active = active&.to_sym
    end

    attr_reader :active

    def items
      person = helpers.current_street_person
      [
        Item.new(key: :home, path: helpers.root_path, icon: "meetinghouse", label_key: "hub.nav_home"),
        Item.new(key: :adventure, path: helpers.street_map_path, icon: "compass", label_key: "hub.nav_adventure"),
        Item.new(key: :word, path: helpers.scripture_library_path, icon: "scripture-book", label_key: "scripture_library.nav"),
        Item.new(key: :church, path: helpers.church_path, icon: "church", label_key: "hub.nav_church"),
        Item.new(
          key: :profile,
          path: person ? helpers.player_profile_path(person) : helpers.street_profile_path,
          icon: "person",
          label_key: "hub.nav_profile"
        )
      ]
    end

    def item_class(item)
      [
        "navigation-dock__item",
        ("is-active" if active == item.key),
        ("is-adventure" if item.key == :adventure)
      ].compact
    end

    def active_index
      items.index { |item| item.key == active } || 0
    end

    def item_aria(item)
      { current: ("page" if active == item.key) }.compact
    end
  end
end
