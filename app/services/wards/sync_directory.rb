module Wards
  class SyncDirectory
    BATCH = 100

    def self.call(rows:)
      new(rows:).call
    end

    def initialize(rows:)
      @rows = Array(rows)
    end

    def call
      created = 0
      updated = 0
      skipped = 0

      @rows.each_slice(BATCH) do |batch|
        Ward.transaction do
          batch.each do |attrs|
            attrs = attrs.symbolize_keys
            if persist(attrs)
              created += 1 if @last_action == :create
              updated += 1 if @last_action == :update
            else
              skipped += 1
            end
          end
        end
      end

      { created:, updated:, skipped: }
    end

    private

      def persist(attrs)
        @last_action = nil
        return if attrs[:name].blank?

        ward = find_existing(attrs)
        if ward
          update_row(ward, attrs)
          @last_action = :update
        else
          create_row(attrs)
          @last_action = :create
        end
        true
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        false
      end

      def find_existing(attrs)
        if attrs[:church_unit_id].present?
          found = Ward.find_by(church_unit_id: attrs[:church_unit_id])
          return found if found
        end

        return Ward.find_by(code: Ward::FEATURED_CODE) if featured_benidorm?(attrs)

        nil
      end

      def featured_benidorm?(attrs)
        city = attrs[:city].to_s.downcase
        address = attrs[:chapel_address].to_s
        city == Ward::FEATURED_CITY && address.match?(/Alfonso Puchades/i)
      end

      def update_row(ward, attrs)
        keep_product = ward.code == Ward::FEATURED_CODE
        ward.assign_attributes(sync_attrs(attrs, keep_name: keep_product))
        ward.church_unit_id = attrs[:church_unit_id] if attrs[:church_unit_id].present?
        ward.listed = true
        ward.save!
      end

      def create_row(attrs)
        token = SecureRandom.urlsafe_base64(24)
        code = nil
        8.times do
          code = Ward.generate_import_code
          Ward.create!(
            sync_attrs(attrs, keep_name: false).merge(
              code: code,
              listed: true,
              emblem: "paloma",
              admin_token_digest: GameSession.digest_token(token)
            )
          )
          return
        rescue ActiveRecord::RecordNotUnique
          next
        rescue ActiveRecord::RecordInvalid => error
          raise unless error.record.errors.of_kind?(:code, :taken)
        end
        raise ActiveRecord::RecordInvalid, Ward.new
      end

      def sync_attrs(attrs, keep_name:)
        {
          chapel_name: attrs[:chapel_name],
          chapel_address: attrs[:chapel_address],
          city: attrs[:city],
          region: attrs[:region],
          postal_code: attrs[:postal_code],
          country_code: attrs[:country_code],
          country_name: attrs[:country_name],
          stake_name: attrs[:stake_name],
          unit_kind: attrs[:unit_kind],
          latitude: attrs[:latitude],
          longitude: attrs[:longitude]
        }.tap do |row|
          row[:name] = attrs[:name].to_s.first(Ward::NAME_MAX) unless keep_name
          row[:church_unit_id] = attrs[:church_unit_id] if attrs[:church_unit_id].present?
          row[:stake_unit_id] = attrs[:stake_unit_id] if attrs[:stake_unit_id].present?
          row[:locator_payload] = attrs[:locator_payload] if attrs[:locator_payload].present?
        end
      end
  end
end
