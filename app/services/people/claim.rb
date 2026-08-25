module People
  class Claim
    ATTEMPTS = ActiveSupport::Cache::MemoryStore.new
    LIMIT = 8
    WINDOW = 15.minutes

    def self.call(ward:, person:, favorite_year:, device_token:)
      new(ward:, person:, favorite_year:, device_token:).call
    end

    def self.reset_attempts!
      ATTEMPTS.clear
    end

    def initialize(ward:, person:, favorite_year:, device_token:)
      @ward = ward
      @person = person
      @favorite_year = favorite_year.to_i
      @device_token = device_token
    end

    def call
      raise Error.new(:missing, I18n.t("errors.people.missing")) unless @person&.ward_id == @ward.id
      raise Error.new(:locked, I18n.t("errors.people.locked")) if locked?

      unless @person.favorite_year == @favorite_year
        record_failure!
        raise Error.new(:year, I18n.t("errors.people.year_miss"))
      end

      ATTEMPTS.delete(attempt_key)
      PersonDevice.find_or_create_by!(person: @person, device_token: @device_token) do |row|
        row.last_seen_at = Time.current
      end
      @person.person_devices.where(device_token: @device_token).update_all(last_seen_at: Time.current)
      @person
    end

    private

      def attempt_key
        "claim:#{@device_token}:#{@person&.id}"
      end

      def locked?
        (ATTEMPTS.read(attempt_key) || 0) >= LIMIT
      end

      def record_failure!
        count = (ATTEMPTS.read(attempt_key) || 0) + 1
        ATTEMPTS.write(attempt_key, count, expires_in: WINDOW)
      end
  end
end
