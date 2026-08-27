module Studies
  class EditorialImporter
    def self.call(program:, path: Rails.root.join("config/study/come_follow_me_2026.yml"))
      data = YAML.safe_load_file(path)
      versions = Array(data["quizzes"]).map do |row|
        page = row.fetch("source_page")
        unit = program.study_units.detect { |candidate| URI.parse(candidate.source_url).path.end_with?("/#{page}") }
        raise ActiveRecord::RecordNotFound, "No imported study unit for source page #{page}" unless unit
        content = row.fetch("content")
        digest = Digest::SHA256.hexdigest(content.to_json)
        version = unit.study_quiz_versions.find_or_initialize_by(content_digest: digest)
        version.assign_attributes(
          version: version.persisted? ? version.version : unit.study_quiz_versions.maximum(:version).to_i + 1,
          status: row.fetch("status", "needs_review"), editorial_locale: "fr", content:,
          published_at: row["status"] == "published" ? (version.published_at || Time.current) : nil
        )
        version.save!
        unit.update!(status: row.fetch("status", "needs_review"))
        version
      end
      program.update!(status: "published") if versions.any?(&:published_at?)
      versions
    end
  end
end
