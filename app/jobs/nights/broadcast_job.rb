module Nights
  class BroadcastJob < ApplicationJob
    queue_as :default

    def perform(night_id, event_id = nil)
      night = GameSession.find_by(id: night_id)
      return unless night

      event = LiveEvent.find_by(id: event_id) if event_id
      Nights::Broadcast.call(night:, event:)
    end
  end
end
