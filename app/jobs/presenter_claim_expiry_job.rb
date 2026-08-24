class PresenterClaimExpiryJob < ApplicationJob
  queue_as :default

  def perform(claim_id)
    claim = PresenterClaim.find_by(id: claim_id)
    Presenters::Expire.call(claim: claim) if claim
  end
end
