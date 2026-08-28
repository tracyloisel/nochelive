require "json"
require "net/http"
require "uri"

module Scriptures
  class Read
    API = "https://www.churchofjesuschrist.org/study/api/v3/language-pages/type/content"
    OPEN_TIMEOUT = 4
    READ_TIMEOUT = 8
    HIT_TTL = 12.hours
    MISS_TTL = 30.seconds
    USER_AGENT = "NocheLive/1.0 (scripture reader)"

    Chapter = Struct.new(:title, :summary, :verses, :source_url, :study, :focus, keyword_init: true)
    Verse = Struct.new(:number, :text, keyword_init: true)

    def self.call(study:, locale: I18n.locale, cite: nil, cache: Rails.cache, public: false)
      new(study:, locale:, cite:, cache:, public:).call
    end

    class << self
      attr_accessor :fetcher
    end

    def self.focus_verses(cite)
      return [] if cite.blank?

      normalized = cite.to_s.tr("–—", "-")
      return [] unless normalized =~ /:(\d+)(?:-(\d+))?\s*\z/

      from = $1.to_i
      to = ($2 || $1).to_i
      return [] if from <= 0 || to < from

      (from..to).to_a
    end

    def self.http_get(uri)
      (fetcher || method(:net_http_get)).call(uri)
    end

    def self.net_http_get(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      req = Net::HTTP::Get.new(uri)
      req["Accept"] = "application/json"
      req["User-Agent"] = USER_AGENT
      res = http.request(req)
      res.body if res.is_a?(Net::HTTPSuccess)
    end

    def initialize(study:, locale: I18n.locale, cite: nil, cache: Rails.cache, public: false)
      @study = study.to_s.strip.sub(%r{\A/+}, "")
      @locale = locale
      @cite = cite
      @cache = cache
      @public = public
    end

    def call
      return unless Quizzes::Scripture.known_study?(@study) || (@public && Scriptures::Reference.known_study?(@study))

      chapter = load_chapter
      return unless chapter

      Chapter.new(
        title: chapter.title,
        summary: chapter.summary,
        verses: chapter.verses,
        source_url: chapter.source_url,
        study: chapter.study,
        focus: self.class.focus_verses(@cite)
      )
    end

    private

      def load_chapter
        cached = @cache.read(hit_key)
        return cached if cached
        return if @cache.read(miss_key)

        chapter = fetch_chapter
        if chapter
          @cache.write(hit_key, chapter, expires_in: HIT_TTL)
        else
          @cache.write(miss_key, true, expires_in: MISS_TTL)
        end
        chapter
      end

      def fetch_chapter
        payload = parse_json(self.class.http_get(api_uri))
        return unless payload.is_a?(Hash)

        html = payload.dig("content", "body").to_s
        return if html.blank?

        title = payload.dig("meta", "title").to_s.strip
        parsed = extract(html)
        return if parsed[:verses].empty?

        Chapter.new(
          title: title.presence || parsed[:title],
          summary: parsed[:summary],
          verses: parsed[:verses],
          source_url: Quizzes::Scripture.page_url(@study, locale: @locale),
          study: @study,
          focus: []
        )
      rescue StandardError
        nil
      end

      def parse_json(body)
        return if body.blank?

        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end

      def extract(html)
        doc = Nokogiri::HTML(html)
        doc.css("footer, .study-notes, sup.marker, .page-break").remove
        doc.css("a.study-note-ref").each { |node| node.replace(node.text) }

        verses = doc.css("p.verse").filter_map do |node|
          number = node.at_css(".verse-number")&.text.to_s.gsub(/\D/, "").to_i
          clone = node.dup
          clone.css(".verse-number").remove
          text = clone.text.gsub(/\s+/, " ").strip
          next if number <= 0 || text.blank?

          Verse.new(number:, text:)
        end

        {
          title: doc.css(".title-number").text.gsub(/\s+/, " ").strip,
          summary: doc.css(".study-summary").map { |node| node.text.gsub(/\s+/, " ").strip }.reject(&:blank?).join(" "),
          verses: verses
        }
      end

      def api_uri
        query = URI.encode_www_form(
          lang: Quizzes::Scripture.lang(@locale),
          uri: "/scriptures/#{@study}"
        )
        URI.parse("#{API}?#{query}")
      end

      def hit_key
        [ "scripture", Quizzes::Scripture.lang(@locale), @study ]
      end

      def miss_key
        [ "scripture-miss", Quizzes::Scripture.lang(@locale), @study ]
      end
  end
end
