module Nights
  class Feed
    WINDOW = 14.days

    def self.call
      new.call
    end

    def call
      { upcoming:, past: }
    end

    private

      def upcoming
        listed.live.where(starts_at: Time.zone.now.beginning_of_day..(Time.zone.now + WINDOW).end_of_day)
          .includes(:ward, :players)
          .order(:starts_at, :id)
      end

      def past
        listed.finished.includes(:ward, :players, :missionaries, :teams).order(starts_at: :desc, id: :desc).limit(10)
      end

      def listed
        GameSession.joins(:ward).merge(Ward.listed)
      end
  end
end
