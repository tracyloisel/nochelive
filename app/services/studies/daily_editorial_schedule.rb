require "time"
require "yaml"
require "digest"

module Studies
  # One Council-reviewed, code-versioned week of Library discoveries.
  #
  # A file being present is never publication authorization. Only a schedule
  # whose publication.state is `scheduled` may be imported into the immutable
  # quiz version. Screen activation remains date-driven in the explicit IANA
  # timezone, so an approved future week can safely be published in advance.
  class DailyEditorialSchedule
    ROOT = Rails.root.join("config/study/library_daily_editorials")
    SCHEMA_VERSION = 2
    FAST_SCHEMA_VERSION = 3
    SUPPORTED_SCHEMA_VERSIONS = [ 1, SCHEMA_VERSION, FAST_SCHEMA_VERSION ].freeze
    HUMAN_DRAMATURGY_REQUIRED_FROM = Date.new(2026, 9, 7)
    WORKFLOW_STATES = %w[draft publish_ready scheduled].freeze
    LEGACY_COUNCIL_GATES = %w[art_gate experience_gate human_voice_gate truth_gate].freeze
    REQUIRED_COUNCIL_GATES = %w[art_gate experience_gate human_dramaturgy_gate human_voice_gate truth_gate].freeze
    REQUIRED_FAST_GATES = %w[quiz_gate translation_gate public_editorial_gate visual_gate human_gate].freeze
    REQUIRED_RENDITIONS = {
      "portrait" => "9:16",
      "tablet" => "4:5",
      "landscape" => "16:9"
    }.freeze

    class Error < StandardError; end

    attr_reader :path, :data

    class << self
      def load(path)
        pathname = Pathname(path)
        payload = YAML.safe_load_file(pathname, aliases: false)
        raise Error, "#{pathname}: schedule must be a YAML object" unless payload.is_a?(Hash)

        new(path: pathname, data: payload)
      rescue Psych::Exception => error
        raise Error, "#{pathname}: invalid YAML: #{error.message}"
      end

      def paths(root: ROOT)
        Pathname(root).glob("*.yml").sort
      end

      def all(root: ROOT)
        paths(root:).map { |path| load(path) }
      end

      def artwork_digest_for(discoveries)
        payload = Array(discoveries).map do |row|
          key = row.is_a?(Hash) ? row["artwork_key"].to_s : ""
          asset = Frontend::MediaManifest.fetch(key)
          {
            "artwork_key" => key,
            "role" => asset&.dig("role"),
            "renditions" => REQUIRED_RENDITIONS.keys.index_with do |name|
              rendition = asset&.dig("renditions", name) || {}
              rendition.slice(
                "source", "source_sha256", "source_width", "source_height", "ratio"
              )
            end
          }
        end
        StudyQuizVersion.content_digest_for(payload)
      end
    end

    def initialize(path:, data:)
      @path = Pathname(path)
      @data = data.deep_stringify_keys
    end

    def id = data["id"].to_s
    def schema_version = data["schema_version"]
    def program_slug = data["program_slug"].to_s
    def study_unit_slug = data["study_unit_slug"].to_s
    def source_dossier = data["source_dossier"].to_s
    def discoveries = data["daily_discoveries"]
    def expedition_pack_ids = Array(data["expedition_pack_ids"]).map(&:to_s)
    def expected_discoveries_digest = data["expected_discoveries_digest"].to_s
    def expected_artwork_digest = data["expected_artwork_digest"].to_s
    def publication = data["publication"].is_a?(Hash) ? data["publication"] : {}
    def workflow_state = publication["state"].to_s
    def council_review = data["council_review"].is_a?(Hash) ? data["council_review"] : {}
    def fast_review = data["fast_review"].is_a?(Hash) ? data["fast_review"] : {}
    def starts_on = parse_date(data["starts_on"])
    def ends_on = parse_date(data["ends_on"])
    def time_zone = Time.find_zone(data["timezone"].to_s)

    def validate!
      issues = validation_errors
      return self if issues.empty?

      raise Error, "#{path}: #{issues.join('; ')}"
    end

    def validation_errors
      issues = []
      issues << "schema_version must be one of #{SUPPORTED_SCHEMA_VERSIONS.join(', ')}" unless SUPPORTED_SCHEMA_VERSIONS.include?(schema_version)
      issues << "id is required" if id.blank?
      issues << "program_slug is required" if program_slug.blank?
      issues << "study_unit_slug is required" if study_unit_slug.blank?
      validate_source_dossier(issues)
      issues << "starts_on is invalid" unless starts_on
      issues << "ends_on is invalid" unless ends_on
      issues << "week must contain exactly seven calendar days" if starts_on && ends_on && ends_on != starts_on + 6.days
      issues << "timezone is invalid" unless time_zone
      issues << "publication.state must be one of #{WORKFLOW_STATES.join(', ')}" unless WORKFLOW_STATES.include?(workflow_state)
      issues << "daily_discoveries must be an array" unless discoveries.is_a?(Array)
      if schema_version == 1 && starts_on && starts_on >= HUMAN_DRAMATURGY_REQUIRED_FROM
        issues << "schema_version #{SCHEMA_VERSION} is required for editions starting on or after #{HUMAN_DRAMATURGY_REQUIRED_FROM.iso8601}"
      end

      validate_activation(issues)
      validate_reviewed_payload(issues)
      validate_council_readiness(issues)
      validate_artwork(issues)
      issues
    end

    def activation_at
      return unless publication["activate_at"].present?

      Time.iso8601(publication["activate_at"].to_s)
    rescue ArgumentError
      nil
    end

    def expires_at
      return unless time_zone && ends_on

      time_zone.local((ends_on + 1.day).year, (ends_on + 1.day).month, (ends_on + 1.day).day)
    end

    def phase(at: Time.current)
      return :draft if workflow_state == "draft"
      return :awaiting_authorization if workflow_state == "publish_ready"
      return :invalid unless activation_at && expires_at

      instant = at.to_time
      return :scheduled if instant < activation_at
      return :expired if instant >= expires_at

      :active
    end

    def scheduled?
      workflow_state == "scheduled"
    end

    def active_local_date?(at: Time.current)
      return false unless scheduled? && time_zone && starts_on && ends_on

      at.in_time_zone(time_zone).to_date.between?(starts_on, ends_on)
    end

    def current_artwork_digest
      self.class.artwork_digest_for(discoveries)
    end

    private

      def validate_activation(issues)
        activate_at = activation_at
        issues << "publication.activate_at is invalid" unless activate_at
        return unless activate_at && time_zone && starts_on

        expected = time_zone.local(starts_on.year, starts_on.month, starts_on.day)
        issues << "publication.activate_at must be local midnight at starts_on in timezone" unless activate_at == expected

        return unless workflow_state == "scheduled"

        issues << "publication.authorized_by is required for scheduled editions" if publication["authorized_by"].to_s.strip.blank?
        issues << "publication.authorized_on is required for scheduled editions" unless parse_date(publication["authorized_on"])
      end

      def validate_reviewed_payload(issues)
        return unless discoveries.is_a?(Array)

        digest = StudyQuizVersion.content_digest_for(discoveries)
        issues << "expected_discoveries_digest is required" if expected_discoveries_digest.blank?
        issues << "daily discoveries changed after Council review" unless secure_digest?(digest, expected_discoveries_digest)
        return unless starts_on && ends_on

        issues.concat(
          DailyDiscoveryContract.call(
            rows: discoveries,
            expedition_pack_ids:,
            starts_on:,
            ends_on:
          )
        )

        expected_dates = (starts_on..ends_on).map(&:iso8601)
        actual_dates = discoveries.filter_map { |row| row["scheduled_on"].to_s if row.is_a?(Hash) }
        issues << "daily_discoveries must cover every date from starts_on through ends_on in order" unless actual_dates == expected_dates
        zones = discoveries.filter_map { |row| row["timezone"].to_s.presence if row.is_a?(Hash) }.uniq
        issues << "daily_discoveries timezone must match the schedule timezone" unless zones == [ time_zone&.name ]
      end

      def validate_council_readiness(issues)
        return if workflow_state == "draft"

        review = review_contract
        prefix = review_contract_name
        issues << "#{prefix}.publish_ready must be true" unless review["publish_ready"] == true
        reviewed_revision = review["revision"]
        if schema_version != 1 && (!reviewed_revision.is_a?(Integer) || reviewed_revision < 1)
          issues << "#{prefix}.revision must be a positive integer"
        end
        required_review_gates.each do |gate|
          issues << "#{prefix}.#{gate} must PASS" unless review.dig(gate, "status") == "PASS"
          if schema_version != 1 && review.dig(gate, "reviewed_revision") != reviewed_revision
            issues << "#{prefix}.#{gate}.reviewed_revision must match #{prefix}.revision"
          end
        end
      end

      def review_contract
        schema_version == FAST_SCHEMA_VERSION ? fast_review : council_review
      end

      def review_contract_name
        schema_version == FAST_SCHEMA_VERSION ? "fast_review" : "council_review"
      end

      def required_review_gates
        return REQUIRED_FAST_GATES if schema_version == FAST_SCHEMA_VERSION

        schema_version == 1 ? LEGACY_COUNCIL_GATES : REQUIRED_COUNCIL_GATES
      end

      def validate_artwork(issues)
        return unless discoveries.is_a?(Array)

        keys = discoveries.filter_map { |row| row["artwork_key"].to_s.presence if row.is_a?(Hash) }
        issues << "daily_discoveries artwork_key values must be unique" unless keys.uniq.size == keys.size
        weekly_sources = []

        discoveries.each_with_index do |row, index|
          next unless row.is_a?(Hash)

          key = row["artwork_key"].to_s
          asset = Frontend::MediaManifest.fetch(key)
          unless asset && asset["role"] == "library_daily_hero"
            issues << "daily_discoveries[#{index}].artwork_key is not in the generated media manifest"
            next
          end

          expected_theme = row["light_family"].to_s.delete_prefix("celestial_")
          if Studies::DailyDiscoveryContract::LIGHT_FAMILIES.include?(row["light_family"].to_s) &&
              asset["theme"].to_s != expected_theme
            issues << "daily_discoveries[#{index}].light_family must match the artwork theme"
          end

          renditions = asset.fetch("renditions", {})
          unless renditions.keys.sort == REQUIRED_RENDITIONS.keys.sort
            issues << "daily_discoveries[#{index}] artwork must contain exactly portrait, tablet and landscape renditions"
            next
          end

          sources = renditions.values.filter_map { |rendition| rendition["source"] }
          weekly_sources.concat(sources)
          issues << "daily_discoveries[#{index}] artwork renditions must use three distinct source files" unless
            sources.size == REQUIRED_RENDITIONS.size && sources.uniq.size == REQUIRED_RENDITIONS.size

          REQUIRED_RENDITIONS.each do |name, ratio|
            rendition = renditions.fetch(name)
            issues << "daily_discoveries[#{index}] artwork #{name} ratio must be #{ratio}" unless
              rendition["ratio"] == ratio
            validate_master_integrity(rendition, index, name, issues)
          end

          references = Array(row["references"])
          issues << "daily_discoveries[#{index}] artwork filenames must contain a biblical reference" unless
            sources.present? && sources.all? { |source| biblical_filename?(source, references) }
        end

        expected_source_count = discoveries.size * REQUIRED_RENDITIONS.size
        issues << "daily artwork must use exactly 21 unique source masters" unless
          expected_source_count == 21 && weekly_sources.size == expected_source_count &&
            weekly_sources.uniq.size == expected_source_count

        return unless schema_version.in?([ SCHEMA_VERSION, FAST_SCHEMA_VERSION ])

        issues << "expected_artwork_digest is required" if expected_artwork_digest.blank?
        issues << "daily artwork changed after Council review" unless
          secure_digest?(current_artwork_digest, expected_artwork_digest)
      end

      def validate_source_dossier(issues)
        path = source_dossier_path
        unless path&.file?
          issues << "source_dossier must point to config/expeditions/*.yml"
          return
        end

        dossier = YAML.safe_load_file(path, aliases: false)
        expected_kind = schema_version == FAST_SCHEMA_VERSION ? "expedition_fast_manifest" : "expedition_council_dossier"
        unless dossier.is_a?(Hash) && dossier["kind"] == expected_kind
          issues << if schema_version == FAST_SCHEMA_VERSION
            "source_dossier must be an expedition FAST manifest"
          else
            "source_dossier must be an expedition Council dossier"
          end
          return
        end

        dossier_schedule = dossier.dig("brief", "schedule")
        unless dossier_schedule.is_a?(Hash) &&
            dossier_schedule["starts_on"].to_s == data["starts_on"].to_s &&
            dossier_schedule["ends_on"].to_s == data["ends_on"].to_s &&
            dossier_schedule["timezone"].to_s == data["timezone"].to_s
          issues << "source_dossier schedule must match starts_on, ends_on and timezone"
        end


        return if schema_version == 1

        if schema_version == FAST_SCHEMA_VERSION
          validate_fast_library_editorial(dossier, issues)
        else
          validate_dossier_library_editorial(dossier, issues)
        end
        return if workflow_state == "draft"

        dossier_revision = dossier.dig("lifecycle", "current_revision")
        unless dossier_revision.is_a?(Integer) && dossier_revision == review_contract["revision"]
          issues << "#{review_contract_name}.revision must match source_dossier lifecycle.current_revision"
        end
      rescue Psych::Exception, Errno::ENOENT
        issues << "source_dossier must be readable Council YAML"
      end

      def validate_dossier_library_editorial(dossier, issues)
        editorial = dossier["library_editorial"]
        unless editorial.is_a?(Hash)
          issues << "source_dossier must contain the canonical library_editorial contract"
          return
        end

        dossier_revision = dossier.dig("lifecycle", "current_revision")
        issues << "source_dossier library_editorial.revision must match lifecycle.current_revision" unless
          editorial["revision"] == dossier_revision
        issues << "source_dossier library_editorial dates and timezone must match the delivery" unless
          editorial["starts_on"].to_s == data["starts_on"].to_s &&
            editorial["ends_on"].to_s == data["ends_on"].to_s &&
            editorial["timezone"].to_s == data["timezone"].to_s
        issues << "source_dossier library_editorial must declare six discoveries and one contemplation" unless
          editorial["composition"] == {
            "discoveries" => 6, "contemplations" => 1, "total_days" => 7
          }
        issues << "source_dossier library_editorial must require all player locales" unless
          Array(editorial["required_locales"]).map(&:to_s).sort == Locale::AVAILABLE.sort
        issues << "source_dossier library_editorial discoveries digest must match the delivery" unless
          secure_digest?(editorial["expected_discoveries_digest"], expected_discoveries_digest)
        issues << "source_dossier library_editorial artwork digest must match the delivery" unless
          secure_digest?(editorial["expected_artwork_digest"], expected_artwork_digest)

        return unless discoveries.is_a?(Array)

        expected_days = discoveries.map do |row|
          {
            "day_id" => row["id"],
            "scheduled_on" => row["scheduled_on"],
            "kind" => row["kind"],
            "references" => row["references"],
            "claim_ids" => row["claim_ids"]
          }.compact
        end
        actual_days = Array(editorial.dig("plan", "days")).map do |row|
          next {} unless row.is_a?(Hash)

          row.slice("day_id", "scheduled_on", "kind", "references", "claim_ids")
        end
        issues << "source_dossier library_editorial plan must match the seven delivered days" unless
          actual_days == expected_days
      end

      def validate_fast_library_editorial(dossier, issues)
        runtime = dossier.dig("fast", "runtime_export")
        editorial = runtime&.dig("library_editorial")
        unless editorial.is_a?(Hash)
          issues << "source_dossier must contain fast.runtime_export.library_editorial"
          return
        end

        dossier_revision = dossier.dig("lifecycle", "current_revision")
        issues << "source_dossier FAST library editorial revision must match lifecycle.current_revision" unless
          editorial["revision"] == dossier_revision
        issues << "source_dossier FAST library editorial dates and timezone must match the delivery" unless
          editorial["starts_on"].to_s == data["starts_on"].to_s &&
            editorial["ends_on"].to_s == data["ends_on"].to_s &&
            editorial["timezone"].to_s == data["timezone"].to_s
        issues << "source_dossier FAST library editorial must declare six discoveries and one contemplation" unless
          editorial["composition"] == {
            "discoveries" => 6, "contemplations" => 1, "total_days" => 7
          }
        issues << "source_dossier FAST library editorial must require all player locales" unless
          Array(editorial["required_locales"]).map(&:to_s).sort == Locale::AVAILABLE.sort
        issues << "source_dossier FAST library editorial discoveries digest must match the delivery" unless
          secure_digest?(editorial["expected_discoveries_digest"], expected_discoveries_digest)
        issues << "source_dossier FAST library editorial artwork digest must match the delivery" unless
          secure_digest?(editorial["expected_artwork_digest"], expected_artwork_digest)

        if workflow_state != "draft"
          issues << "source_dossier FAST library editorial must be approved" unless editorial["status"] == "approved"
          issues << "source_dossier FAST accessibility copy must be approved" unless
            runtime.dig("accessibility_copy", "status") == "approved"
          issues << "source_dossier FAST runtime copy still has unresolved human decisions" unless
            Array(runtime["unresolved_human_copy"]).empty?
        end

        return unless discoveries.is_a?(Array)

        expected_days = discoveries.map do |row|
          {
            "day_id" => row["id"],
            "scheduled_on" => row["scheduled_on"],
            "kind" => row["kind"],
            "references" => row["references"],
            "claim_ids" => row["claim_ids"]
          }.compact
        end
        actual_days = Array(editorial.dig("plan", "days")).map do |row|
          next {} unless row.is_a?(Hash)

          row.slice("day_id", "scheduled_on", "kind", "references", "claim_ids")
        end
        issues << "source_dossier FAST library editorial plan must match the seven delivered days" unless
          actual_days == expected_days
      end

      def source_dossier_path
        return if source_dossier.blank?

        root = Rails.root.join("config/expeditions").realpath
        candidate = Rails.root.join(source_dossier).realpath
        candidate if candidate.dirname == root && candidate.extname == ".yml"
      rescue Errno::ENOENT
        nil
      end

      def biblical_filename?(source, references)
        basename = File.basename(source.to_s).downcase
        references.any? do |reference|
          _canon, book, chapter = reference.to_s.split("/", 3)
          next false unless book.present? && chapter.present?

          token = "#{book.downcase.gsub(/[^a-z0-9]/, '')}#{chapter.downcase.gsub(/[^a-z0-9-]/, '')}"
          basename.match?(/(?:\A|[^a-z0-9])#{Regexp.escape(token)}(?!\d)/)
        end
      end

      def validate_master_integrity(rendition, index, name, issues)
        source = rendition["source"].to_s
        digest = rendition["source_sha256"].to_s
        prefix = "daily_discoveries[#{index}] artwork #{name}"
        issues << "#{prefix} must include source dimensions" unless
          rendition["source_width"].to_i.positive? && rendition["source_height"].to_i.positive?
        issues << "#{prefix} must include a source SHA-256" unless digest.match?(/\A[0-9a-f]{64}\z/)

        master = Rails.root.join("media/masters", source)
        unless master.file?
          issues << "#{prefix} source master is missing"
          return
        end

        issues << "#{prefix} source master changed after manifest generation" unless
          digest.match?(/\A[0-9a-f]{64}\z/) && secure_digest?(Digest::SHA256.file(master).hexdigest, digest)
      end

      def parse_date(value)
        Date.iso8601(value.to_s)
      rescue Date::Error
        nil
      end

      def secure_digest?(left, right)
        left = left.to_s
        right = right.to_s
        left.bytesize == right.bytesize && ActiveSupport::SecurityUtils.secure_compare(left, right)
      end
  end
end
