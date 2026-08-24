module Presenters
  class Broadcast
    def self.call(night:, claim: nil)
      new(night:, claim:).call
    end

    def initialize(night:, claim:)
      @night = night
      @claim = claim
    end

    def call
      night = @night.reload
      Turbo::StreamsChannel.broadcast_replace_to(
        night.presenter_stream,
        target: "night_presenter",
        partial: "presenter/consoles/frame",
        locals: { night: night }
      )
      return unless @claim

      Turbo::StreamsChannel.broadcast_replace_to(
        night.claim_stream(@claim.device_digest),
        target: "claim_wait",
        partial: "presenter/claims/wait",
        locals: { night: night, claim: @claim.reload }
      )
    end
  end
end
