module Studies
  # Adds one reviewed seven-day editorial schedule to the current published
  # weekly quiz without ever mutating that published payload in place.
  class PublishDailyDiscoveries
    class Error < StandardError; end

    def self.call(study_unit:, discoveries:, expected_discoveries_digest:, at: Time.current)
      new(
        study_unit:,
        discoveries:,
        expected_discoveries_digest:,
        at:
      ).call
    end

    def initialize(study_unit:, discoveries:, expected_discoveries_digest:, at:)
      @study_unit = study_unit
      @discoveries = discoveries.deep_dup
      @expected_discoveries_digest = expected_discoveries_digest.to_s
      @at = at
    end

    def call
      ensure_reviewed_payload!

      StudyQuizVersion.transaction do
        unit = locked_unit
        source = unit.study_quiz_versions.lock.find_by(status: "published")
        raise Error, "study unit has no published quiz version" unless source

        return source if same_discoveries?(source.daily_discoveries, @discoveries)

        content = source.content.deep_dup.merge("daily_discoveries" => @discoveries)
        digest = StudyQuizVersion.content_digest_for(content)
        candidate = reusable_candidate(unit, digest)
        reject_conflicting_review!(unit, candidate)
        candidate ||= unit.study_quiz_versions.create!(
          version: unit.study_quiz_versions.maximum(:version).to_i + 1,
          status: "needs_review",
          editorial_locale: source.editorial_locale,
          content:,
          content_digest: digest
        )

        Studies::PublishQuizVersion.call(
          version: candidate,
          expected_content_digest: candidate.content_digest,
          at: @at
        )
      end
    rescue ActiveRecord::RecordInvalid => error
      raise Error, error.record.errors.full_messages.to_sentence
    rescue Studies::PublishQuizVersion::Error => error
      raise Error, error.message
    end

    private

      def ensure_reviewed_payload!
        raise Error, "study unit must be persisted" unless @study_unit.is_a?(StudyUnit) && @study_unit.persisted?
        raise Error, "daily discoveries must be an array" unless @discoveries.is_a?(Array)
        raise Error, "reviewed daily discovery digest is required" if @expected_discoveries_digest.blank?

        actual = StudyQuizVersion.content_digest_for(@discoveries)
        return if same_digest?(actual, @expected_discoveries_digest)

        raise Error, "daily discoveries changed after review"
      end

      def locked_unit
        unit = StudyUnit.lock.find(@study_unit.id)
        unit.lock!
        unit
      end

      def reusable_candidate(unit, digest)
        candidate = unit.study_quiz_versions.lock.find_by(content_digest: digest)
        return unless candidate
        return candidate if candidate.status == "needs_review"

        raise Error, "matching daily discovery candidate is not reviewable"
      end

      def reject_conflicting_review!(unit, candidate)
        conflict = unit.study_quiz_versions
          .where(status: "needs_review")
          .where.not(id: candidate&.id)
          .exists?
        raise Error, "study unit already has a different version in review" if conflict
      end

      def same_discoveries?(left, right)
        same_digest?(
          StudyQuizVersion.content_digest_for(left),
          StudyQuizVersion.content_digest_for(right)
        )
      end

      def same_digest?(left, right)
        left = left.to_s
        right = right.to_s
        left.bytesize == right.bytesize && ActiveSupport::SecurityUtils.secure_compare(left, right)
      end
  end
end
