module Nights
  class LifecycleJob < ApplicationJob
    queue_as :default

    def perform(night_id, expected_starts_at)
      night = GameSession.find_by(id: night_id)
      return unless night && night.starts_at.to_i == expected_starts_at.to_i

      Nights::Reconcile.call(night:)
    end
  end
end
