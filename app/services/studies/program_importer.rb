require "net/http"

module Studies
  class ProgramImporter
    Result = Data.define(:program, :created, :updated, :unchanged)

    class << self
      attr_accessor :transport

      def call(url:, dry_run: false)
        new(url:, dry_run:).call
      end
    end

    def initialize(url:, dry_run: false)
      @url = sanitize_url(url)
      @dry_run = dry_run
    end

    def call
      html = fetch(@url)
      document = Nokogiri::HTML(html)
      year = @url[/\b(20\d{2})\b/, 1]&.to_i || Date.current.year
      entries = extract_entries(document, year:)
      raise ArgumentError, "No Come, Follow Me units found at #{@url}" if entries.empty?

      digest = Digest::SHA256.hexdigest(entries.to_json)
      program = StudyProgram.find_or_initialize_by(slug: "come-follow-me-old-testament-#{year}-fr")
      program.assign_attributes(
        title: "Viens et suis-moi — Ancien Testament #{year}",
        year:, canon: "old_testament", locale: "fr", source_url: @url,
        source_digest: digest, imported_at: Time.current
      )
      return Result.new(program:, created: 0, updated: 0, unchanged: entries.size) if @dry_run

      program.save!
      counts = { created: 0, updated: 0, unchanged: 0 }
      StudyUnit.transaction do
        tracked = %w[kind position title source_url starts_on ends_on scripture_refs]
        previous = program.study_units.index_by(&:slug).transform_values { |unit| unit.attributes.slice(*tracked) }
        program.study_units.update_all("position = -id")
        entries.each do |attributes|
          unit = program.study_units.find_or_initialize_by(slug: attributes.fetch(:slug))
          before = previous[unit.slug]
          unit.assign_attributes(attributes)
          key = unit.new_record? ? :created : (before == unit.attributes.slice(*tracked) ? :unchanged : :updated)
          unit.save!
          counts[key] += 1
        end
        imported_slugs = entries.map { |attributes| attributes.fetch(:slug) }
        program.study_units.where.not(slug: imported_slugs).update_all(status: "archived")
      end
      Result.new(program:, **counts)
    end

    private

      def sanitize_url(value)
        value.to_s.strip.sub(/[.)]+\z/, "")
      end

      def fetch(url)
        return self.class.transport.call(url) if self.class.transport

        uri = URI.parse(url)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 20) do |http|
          request = Net::HTTP::Get.new(uri.request_uri, "User-Agent" => "NocheLive/1.0 ScriptureProgramImporter")
          http.request(request)
        end
        raise "Program download failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end

      def extract_entries(document, year:)
        links = document.css("a[href]").filter_map do |node|
          title = clean(node.text)
          href = node["href"].to_s
          next if title.blank? || !href.include?("come-follow-me-for-home-and-church-old-testament-#{year}")
          next if href.include?("000-contents") || href.include?("000-spine")

          [ title, URI.join(@url, href).to_s ]
        end.uniq

        week_index = 0
        kind_positions = Hash.new(0)
        links.filter_map do |title, source_url|
          kind = classify(title)
          next unless kind

          kind_positions[kind] += 1
          starts_on = ends_on = nil
          if kind == "week"
            starts_on = Date.new(year - 1, 12, 29) + week_index.weeks
            ends_on = starts_on + 6.days
            week_index += 1
          end
          source_slug = URI.parse(source_url).path.split("/").last
          {
            slug: "#{kind}-#{source_slug}", kind:, position: kind_positions[kind], title:, source_url:,
            starts_on:, ends_on:, scripture_refs: scripture_refs(title, kind:), status: "imported"
          }
        end
      end

      def classify(title)
        return "appendix" if title.match?(/\AAnnexe\s+[A-D]/i)
        return "reflection" if title.start_with?("Réflexions à garder à l’esprit")
        return "week" if title.match?(/\A(?:\d{1,2}|1er)\s/)
        return "introduction" if title.match?(/conversion|Utiliser Viens|améliorer l’apprentissage|Aperçu de l’Ancien/i)

        nil
      end

      def scripture_refs(title, kind:)
        return [] unless kind == "week"

        refs = title.split(/\s:\s/, 2).last
        refs == title ? [] : [ refs ]
      end

      def clean(value)
        value.to_s.gsub(/\p{Space}+/, " ").strip
      end
  end
end
