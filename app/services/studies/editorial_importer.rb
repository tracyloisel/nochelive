module Studies
  class EditorialImporter
    def self.call(program:, path: Rails.root.join("config/study/come_follow_me_2026.yml"), source_pages: nil)
      data = YAML.safe_load_file(path)
      rows = Array(data["quizzes"])
      if source_pages
        selected_pages = Array(source_pages).map(&:to_s).uniq
        rows = rows.select { |row| selected_pages.include?(row["source_page"].to_s) }
      end

      StudyQuizVersion.transaction do
        program.lock!
        versions = rows.map do |row|
          page = row.fetch("source_page")
          unit = program.study_units.detect { |candidate| URI.parse(candidate.source_url).path.end_with?("/#{page}") }
          raise ActiveRecord::RecordNotFound, "No imported study unit for source page #{page}" unless unit

          import_row!(unit:, row:)
        end
        program.update!(status: "published") if versions.any? { |version| version.status == "published" }
        versions
      end
    end

    def self.import_row!(unit:, row:)
      unit.lock!
      versions = unit.study_quiz_versions.lock.order(:version).to_a
      requested_status = row.fetch("status", "needs_review")
      content = row.fetch("content").deep_dup
      preserve_published_daily_discoveries!(content, versions)
      digest = StudyQuizVersion.content_digest_for(content)

      if requested_status == "published"
        import_published!(unit:, versions:, content:, digest:)
      else
        import_unpublished!(unit:, versions:, requested_status:, content:, digest:)
      end
    end
    private_class_method :import_row!

    def self.preserve_published_daily_discoveries!(content, versions)
      return if content.key?("daily_discoveries")

      source = versions
        .select { |version| version.status == "published" && version.daily_discoveries? }
        .max_by(&:version)
      content["daily_discoveries"] = source.daily_discoveries.deep_dup if source
    end
    private_class_method :preserve_published_daily_discoveries!

    def self.import_published!(unit:, versions:, content:, digest:)
      published = versions.select { |version| version.status == "published" }
      current = published.find { |version| version.content_digest == digest }
      if current&.content_digest_current? && published.one?
        unit.update!(status: "published") unless unit.status == "published"
        return current
      end

      candidate = versions.find { |version| version.status == "needs_review" && version.content_digest == digest }
      candidate ||= unit.study_quiz_versions.create!(
        version: next_version(versions),
        status: "needs_review",
        editorial_locale: "fr",
        content:,
        content_digest: digest
      )

      Studies::PublishQuizVersion.call(
        version: candidate,
        expected_content_digest: digest,
        at: Time.current
      )
    end
    private_class_method :import_published!

    def self.import_unpublished!(unit:, versions:, requested_status:, content:, digest:)
      matching = versions.find do |version|
        version.content_digest == digest && [ requested_status, "published" ].include?(version.status)
      end
      return matching if matching

      version = unit.study_quiz_versions.create!(
        version: next_version(versions),
        status: requested_status,
        editorial_locale: "fr",
        content:,
        content_digest: digest
      )
      unit.update!(status: requested_status) unless unit.status == "published"
      version
    end
    private_class_method :import_unpublished!

    def self.next_version(versions)
      versions.map(&:version).max.to_i + 1
    end
    private_class_method :next_version
  end
end
