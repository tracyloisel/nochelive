module ScriptureCircles
  class RateLimit
    Exceeded = Class.new(StandardError)

    LIMITS = {
      post: [ 6, 10.minutes ],
      report: [ 10, 7.days ],
      ballot: [ 30, 1.day ],
      conversation_vote: [ 60, 1.day ],
      post_vote: [ 120, 1.day ]
    }.freeze

    def self.check!(action:, person:, device_digest: nil, cache: Rails.cache)
      limit, window = LIMITS.fetch(action.to_sym)
      bucket = Time.current.to_i / window.to_i
      actors = [ "person:#{person.id}", ("device:#{device_digest}" if device_digest.present?) ].compact
      actors.each do |actor|
        key = "scripture-circle-rate:v1:#{action}:#{actor}:#{bucket}"
        cache.write(key, 0, expires_in: window, unless_exist: true)
        raise Exceeded if cache.increment(key, 1, expires_in: window).to_i > limit
      end
      true
    end
  end
end
