require "net/http"

module Studies
  class ProgramImporter
    Result = Data.define(:program, :created, :updated, :unchanged)
    OFFICIAL_LANGUAGES = { "es" => "spa", "fr" => "fra", "en" => "eng", "pt-BR" => "por" }.freeze

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
      year = @url[/\b(20\d{2})\b/, 1]&.to_i || Date.current.year
      sources = localized_sources
      french_url, french_document = sources.fetch("fr")
      entries = extract_entries(french_document, year:, base_url: french_url)
      raise ArgumentError, "No Come, Follow Me units found at #{@url}" if entries.empty?

      localized_titles = sources.transform_values { |url, document| extract_titles(document, base_url: url) }
      entries.each do |attributes|
        source_slug = URI.parse(attributes.fetch(:source_url)).path.split("/").last
        attributes[:copy] = localized_copy(source_slug:, kind: attributes.fetch(:kind), localized_titles:)
      end

      digest = Digest::SHA256.hexdigest(entries.to_json)
      program = StudyProgram.find_or_initialize_by(slug: "come-follow-me-old-testament-#{year}-fr")
      program.assign_attributes(
        title: "Viens et suis-moi — Ancien Testament #{year}",
        year:, canon: "old_testament", locale: "fr", source_url: french_url,
        source_digest: digest, imported_at: Time.current
      )
      return Result.new(program:, created: 0, updated: 0, unchanged: entries.size) if @dry_run

      program.save!
      counts = { created: 0, updated: 0, unchanged: 0 }
      StudyUnit.transaction do
        tracked = %w[kind position title source_url starts_on ends_on scripture_refs copy]
        previous = program.study_units.index_by(&:slug).transform_values { |unit| unit.attributes.slice(*tracked) }
        program.study_units.update_all("position = -id")
        entries.each do |attributes|
          unit = program.study_units.find_or_initialize_by(slug: attributes.fetch(:slug))
          before = previous[unit.slug]
          unit.assign_attributes(attributes.merge(copy: unit.copy.deep_merge(attributes.fetch(:copy))))
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

      def localized_sources
        OFFICIAL_LANGUAGES.to_h do |locale, language|
          url = localized_url(language)
          [ locale, [ url, Nokogiri::HTML(fetch(url)) ] ]
        end
      end

      def localized_url(language)
        uri = URI.parse(@url)
        query = URI.decode_www_form(uri.query.to_s).reject { |key, _value| key == "lang" }
        uri.query = URI.encode_www_form(query + [ [ "lang", language ] ])
        uri.to_s
      end

      def extract_entries(document, year:, base_url:)
        links = program_links(document, base_url:)

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

      def extract_titles(document, base_url:)
        program_links(document, base_url:).to_h do |title, source_url|
          [ URI.parse(source_url).path.split("/").last, title ]
        end
      end

      def program_links(document, base_url:)
        document.css("a[href]").filter_map do |node|
          title = clean(node.text)
          href = node["href"].to_s
          next if title.blank? || !href.include?("come-follow-me-for-home-and-church-old-testament-")
          next if href.include?("000-contents") || href.include?("000-spine")

          [ title, URI.join(base_url, href).to_s ]
        end.uniq
      end

      def localized_copy(source_slug:, kind:, localized_titles:)
        OFFICIAL_LANGUAGES.each_with_object({}) do |(locale, _language), copy|
          title = localized_titles.fetch(locale)[source_slug]
          raise ArgumentError, "Missing #{locale} title for Come, Follow Me unit #{source_slug}" if title.blank?

          copy[locale] = { "title" => title }
          refs = scripture_refs(title, kind:)
          copy[locale]["scripture_refs"] = refs if refs.any?
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

        refs = title.split(/\s*:\s*/, 2).last
        refs == title ? [] : [ refs ]
      end

      def clean(value)
        value.to_s.gsub(/\p{Space}+/, " ").strip
      end
  end
end
