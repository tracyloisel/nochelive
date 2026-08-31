class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @entry = build_entry
    return reject unless @entry

    @entry = Presences::Registry.enter(**@entry).entry
  rescue Redis::BaseError => error
    Rails.error.report(error, context: { component: "presence_channel", action: "subscribe" })
    reject
  end

  def heartbeat
    Presences::Registry.touch(@entry) if @entry
  rescue Redis::BaseError => error
    Rails.error.report(error, context: { component: "presence_channel", action: "heartbeat" })
  end

  def unsubscribed
    return unless @entry

    Presences::Registry.leave(@entry)
  rescue Redis::BaseError => error
    Rails.error.report(error, context: { component: "presence_channel", action: "unsubscribe" })
  end

  private

    def build_entry
      case params[:scope]
      when "street"
        street_entry
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

end
