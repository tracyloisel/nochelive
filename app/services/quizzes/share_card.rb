module Quizzes
  class ShareCard
    Result = Struct.new(:title, :text, :url, :pack_title, :ward_name, :score, :stars, keyword_init: true)

    def self.call(person:, ward:, pack_id:, score:, stars: nil, host: nil)
      new(person:, ward:, pack_id:, score:, stars:, host:).call
    end

    def initialize(person:, ward:, pack_id:, score:, stars: nil, host: nil)
      @person = person
      @ward = ward
      @pack_id = pack_id
      @score = score.to_i
      @stars = stars || Stars.call(score: @score)
      @host = host
    end

    def call
      pack = QuizDefinition.catalog.find_pack(@pack_id)
      pack_title = pack.copy(:title)
      url = Rails.application.routes.url_helpers.root_url(rama: @ward.code, **public_url_options)
      text = I18n.t(
        "street.share_message",
        score: @score,
        pack: pack_title,
        ward: @ward.name
      )
      title = I18n.t("street.share_title", name: @person&.given_name || I18n.t("street.share_guest"))
      Result.new(title:, text:, url:, pack_title:, ward_name: @ward.name, score: @score, stars: @stars)
    end

    private

      def public_url_options
        host = (@host.presence || Rails.configuration.x.app_host).to_s.sub(%r{\Ahttps?://}i, "")
        options = { host: host }
        options[:protocol] = "https" unless local_host?(host)
        options
      end

      def local_host?(host)
        hostname = host.split(":").first
        hostname == "localhost" || hostname == "127.0.0.1"
      end
  end
end
