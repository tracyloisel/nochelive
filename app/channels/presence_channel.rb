class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @entry = build_entry
    return reject unless @entry

    change = Presences::Registry.enter(**@entry)
    @entry = change.entry
    Presences::BroadcastChange.call(change)
  rescue Redis::BaseError => error
    Rails.error.report(error, context: { component: "presence_channel", action: "subscribe" })
    reject
  end

  def heartbeat
    Presences::BroadcastChange.call(Presences::Registry.touch(@entry)) if @entry
  rescue Redis::BaseError => error
    Rails.error.report(error, context: { component: "presence_channel", action: "heartbeat" })
  end

  def unsubscribed
    return unless @entry

    Presences::BroadcastChange.call(Presences::Registry.leave(@entry))
  rescue Redis::BaseError => error
    Rails.error.report(error, context: { component: "presence_channel", action: "unsubscribe" })
  end

  private

    def build_entry
      case params[:scope]
      when "street"
        street_entry
      when "night"
        night_entry
      end
    end

    def street_entry
      person = Person.find_signed(params[:token], purpose: :street_presence)
      return unless person

      {
        connection_id: SecureRandom.uuid,
        person_id: person.id,
        ward_id: person.ward_id,
        role: "street"
      }
    end

    def night_entry
      player = Player.find_signed(params[:token], purpose: :night_presence)
      return unless player

      {
        connection_id: SecureRandom.uuid,
        person_id: player.person_id,
        ward_id: player.game_session.ward_id,
        player_id: player.id,
        night_id: player.game_session_id,
        team_id: player.team&.id,
        role: player.role,
        location: player.location
      }
    end
end
