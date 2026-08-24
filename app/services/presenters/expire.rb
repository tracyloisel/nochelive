module Presenters
  class Expire
    def self.call(claim:)
      new(claim:).call
    end

    def initialize(claim:)
      @claim = claim
    end

    def call
      return unless @claim
      return @claim unless @claim.pending?
      return @claim unless @claim.expired?

      Presenters::Grant.call(claim: @claim)
    end
  end
end
