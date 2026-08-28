module Platform
  class StatsScreen
    Stats = Struct.new(
      :people, :wards, :countries, :languages,
      :answers, :correct, :wrong, :path_share,
      :duels, :nights, :teams,
      :invitations_sent, :invitations_opened, :friends_joined, :invitation_duels_completed, :invitation_share,
      :world,
      keyword_init: true
    )

    def self.call(person: nil, ward: nil, device_digest:)
      new(person:, ward:, device_digest:).call
    end

    def initialize(person: nil, ward: nil, device_digest:)
      @person = person
      @ward = ward
      @digest = device_digest.to_s
    end

    def call
      stats = Platform::Stats.call
      hud = Huds::Present.from_screen(
        screen: Hubs::Screen.call(
          device_digest: @digest,
          person: @person,
          ward: @ward
        ),
        rank_up: false
      )
      Result.new(stats: stats, hud: hud)
    end

    Result = Struct.new(:stats, :hud, keyword_init: true)
  end
end
