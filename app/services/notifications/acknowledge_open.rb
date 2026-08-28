module Notifications
  class AcknowledgeOpen
    def self.call(delivery:, person:, path: nil)
      return false unless delivery&.person_id == person&.id
      return false if path.present? && URI.parse(delivery.destination).path != URI.parse(path).path

      delivery.update!(status: "opened", opened_at: delivery.opened_at || Time.current)
      true
    rescue URI::InvalidURIError
      false
    end
  end
end
