module StreetChallengesHelper
  def duel_calendar_date(value)
    l(value.to_date)
  end

  def duel_time_left(expires_at, now: Time.current)
    seconds = [(expires_at - now).ceil, 0].max
    return t("duel_campus.time_left.now") if seconds.zero?

    unit, count = if seconds >= 1.day
      [:days, (seconds.to_f / 1.day).ceil]
    elsif seconds >= 1.hour
      [:hours, (seconds.to_f / 1.hour).ceil]
    else
      [:minutes, (seconds.to_f / 1.minute).ceil]
    end
    t("duel_campus.time_left.#{unit}", count:)
  end
end
