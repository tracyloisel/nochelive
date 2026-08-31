module Studies
  # Database-free validation shared by code-versioned editorial schedules and
  # immutable StudyQuizVersion records.
  class DailyDiscoveryContract
    KINDS = %w[discovery contemplation].freeze
    STATUSES = %w[approved].freeze
    COPY_FIELDS = %w[eyebrow title setup question cta_label].freeze
    MOTIONS = %w[still ambient].freeze
    AUDIO_MODES = %w[silent opt_in].freeze

    def self.call(rows:, expedition_pack_ids:, starts_on:, ends_on:)
      new(rows:, expedition_pack_ids:, starts_on:, ends_on:).call
    end

    def initialize(rows:, expedition_pack_ids:, starts_on:, ends_on:)
      @rows = rows
      @expedition_pack_ids = Array(expedition_pack_ids).map(&:to_s).uniq
      @starts_on = starts_on
      @ends_on = ends_on
    end

    def call
      return [ "daily_discoveries must be an array" ] unless @rows.is_a?(Array)

      issues = []
      issues << "daily_discoveries must contain exactly 7 entries" unless @rows.size == 7
      @rows.each_with_index { |row, index| validate_row(row, index, issues) }
      validate_schedule(issues)
      issues
    end

    private

      def validate_row(row, index, issues)
        prefix = "daily_discoveries[#{index}]"
        unless row.is_a?(Hash)
          issues << "#{prefix} must be an object"
          return
        end

        issues << "#{prefix}.id is required" if row["id"].to_s.strip.blank?
        issues << "#{prefix}.kind is invalid" unless KINDS.include?(row["kind"].to_s)
        issues << "#{prefix}.status must be approved" unless STATUSES.include?(row["status"].to_s)
        issues << "#{prefix}.reference is invalid" unless Scriptures::Reference.known_study?(row["reference"])
        validate_route(row, prefix, issues)
        issues << "#{prefix}.claim_ids must not be empty" if normalized_claim_ids(row).empty?
        issues << "#{prefix}.artwork_key is required" if row["artwork_key"].to_s.strip.blank?
        issues << "#{prefix}.light_family is required" if row["light_family"].to_s.strip.blank?
        issues << "#{prefix}.depiction_mode is required" if row["depiction_mode"].to_s.strip.blank?
        issues << "#{prefix}.motion is invalid" unless MOTIONS.include?(row["motion"].to_s)
        issues << "#{prefix}.audio is invalid" unless AUDIO_MODES.include?(row["audio"].to_s)
        issues << "#{prefix}.scheduled_on is invalid" unless parse_date(row["scheduled_on"])
        issues << "#{prefix}.timezone is invalid" unless Time.find_zone(row["timezone"].to_s)
        validate_gate(row, index, "truth_gate", issues)
        validate_gate(row, index, "experience_gate", issues)
        validate_locales(row, index, issues)
      end

      def validate_gate(row, index, key, issues)
        gate = row[key]
        revision = Integer(row["revision"], exception: false)
        reviewed_revision = Integer(gate.is_a?(Hash) ? gate["reviewed_revision"] : nil, exception: false)
        prefix = "daily_discoveries[#{index}].#{key}"
        issues << "#{prefix} must pass the current revision" unless
          revision&.positive? && gate.is_a?(Hash) && gate["status"] == "PASS" && reviewed_revision == revision
      end

      def validate_route(row, prefix, issues)
        references = Array(row["references"]).map(&:to_s).uniq
        issues << "#{prefix}.references must not be empty" if references.empty?
        issues << "#{prefix}.references contains an invalid study" unless
          references.all? { |study| Scriptures::Reference.known_study?(study) }
        issues << "#{prefix}.references must include reference" unless references.include?(row["reference"].to_s)

        pack_id = row["pack_id"].to_s.presence
        if row["kind"].to_s == "discovery"
          if @expedition_pack_ids.any?
            issues << "#{prefix}.pack_id must belong to the expedition" unless
              pack_id && @expedition_pack_ids.include?(pack_id)
          elsif pack_id
            issues << "#{prefix}.pack_id requires an expedition"
          end
        elsif pack_id && !@expedition_pack_ids.include?(pack_id)
          issues << "#{prefix}.pack_id must belong to the expedition"
        end
      end

      def validate_locales(row, index, issues)
        %w[copy alt disclosure].each do |key|
          localized = row[key]
          unless localized.is_a?(Hash) && localized.keys.map(&:to_s).sort == Locale::AVAILABLE.sort
            issues << "daily_discoveries[#{index}].#{key} must contain exactly #{Locale::AVAILABLE.join(', ')}"
            next
          end

          localized.each do |locale, value|
            if key == "copy"
              missing = COPY_FIELDS.reject { |field| value.is_a?(Hash) && value[field].to_s.strip.present? }
              issues << "daily_discoveries[#{index}].copy.#{locale} is missing #{missing.join(', ')}" if missing.any?
            elsif value.to_s.strip.blank?
              issues << "daily_discoveries[#{index}].#{key}.#{locale} is required"
            end
          end
        end
      end

      def validate_schedule(issues)
        hashes = @rows.select { |row| row.is_a?(Hash) }
        ids = hashes.map { |row| row["id"].to_s.strip }.reject(&:blank?)
        dates = hashes.filter_map { |row| parse_date(row["scheduled_on"]) }
        zones = hashes.filter_map { |row| row["timezone"].to_s.presence }.uniq
        kinds = hashes.map { |row| row["kind"].to_s }
        issues << "daily_discoveries ids must be unique" unless ids.uniq.size == ids.size
        issues << "daily_discoveries scheduled_on dates must be unique" unless dates.uniq.size == dates.size
        issues << "daily_discoveries must use one explicit timezone" unless zones.one? && Time.find_zone(zones.first)
        issues << "daily_discoveries must contain six discoveries followed by one contemplation" unless
          kinds == [ *Array.new(6, "discovery"), "contemplation" ]

        unless @starts_on && @ends_on
          issues << "daily_discoveries require a dated study unit"
          return
        end

        issues << "daily_discoveries must stay inside the study week" unless
          dates.all? { |date| date.between?(@starts_on, @ends_on) }
      end

      def normalized_claim_ids(row)
        Array(row["claim_ids"]).filter_map { |claim_id| claim_id.to_s.strip.presence }.uniq
      end

      def parse_date(value)
        Date.iso8601(value.to_s)
      rescue Date::Error
        nil
      end
  end
end
