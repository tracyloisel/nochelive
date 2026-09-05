module Studies
  # Publishes one reviewed immutable payload while retiring the previous
  # version for the same study unit in the same database transaction.
  class PublishQuizVersion
    class Error < StandardError; end

    def self.call(version:, expected_content_digest:, at: Time.current)
      new(version:, expected_content_digest:, at:).call
    end

    def initialize(version:, expected_content_digest:, at:)
      @version = version
      @expected_content_digest = expected_content_digest.to_s
      @at = at
    end

    def call
      raise Error, "version must be persisted" unless @version.is_a?(StudyQuizVersion) && @version.persisted?
      raise Error, "publication time is required" unless @at.respond_to?(:to_time)

      StudyQuizVersion.transaction do
        unit = @version.study_unit
        unit.lock!
        version = unit.study_quiz_versions.lock.find(@version.id)
        ensure_publishable!(version, unit)

        version.assign_attributes(status: "published", published_at: @at)
        raise Error, version.errors.full_messages.to_sentence unless version.valid?

        unit.study_quiz_versions
          .where(status: "published")
          .where.not(id: version.id)
          .lock
          .order(:id)
          .each { |published| published.update!(status: "retired") }

        version.save!
        unit.update!(status: "published") unless unit.status == "published"
        program = unit.study_program
        program.update!(status: "published") unless program.status == "published"
        version
      end
    end

    private

      def ensure_publishable!(version, unit)
        raise Error, "version must be needs_review" unless version.status == "needs_review"
        raise Error, "archived study units cannot be published" if unit.status == "archived"
        raise Error, "archived study programs cannot be published" if unit.study_program.status == "archived"
        raise Error, "expected content digest is required" if @expected_content_digest.blank?
        raise Error, "content changed after review" unless same_digest?(version.content_digest, @expected_content_digest)
        raise Error, "stored content digest is stale" unless version.content_digest_current?
        ensure_expedition_rama_hero!(version)
      end

      def ensure_expedition_rama_hero!(version)
        return unless version.expedition?

        issues = Expeditions::RamaHero.validation_errors(expedition: version.expedition)
        return if issues.empty?

        raise Error, "expedition cannot be published: #{issues.to_sentence}"
      end

      def same_digest?(left, right)
        left = left.to_s
        right = right.to_s
        left.bytesize == right.bytesize && ActiveSupport::SecurityUtils.secure_compare(left, right)
      end
  end
end
