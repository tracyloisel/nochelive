module Nights
  class ScheduleLifecycle
    def self.call(night:)
      [ night.lobby_at, night.starts_at, night.ends_at ].each do |moment|
        if moment.future?
          Nights::LifecycleJob.set(wait_until: moment).perform_later(night.id, night.starts_at.to_i)
        end
      end
    end
  end
end
