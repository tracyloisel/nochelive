module Quizzes
  class ShareCard
    Result = Struct.new(:title, :text, :url, :pack_title, :ward_name, :score, :stars, keyword_init: true)

    def self.call(person:, ward:, pack_id:, score:, stars: nil)
      new(person:, ward:, pack_id:, score:, stars:).call
    end

    def initialize(person:, ward:, pack_id:, score:, stars: nil)
      @person = person
      @ward = ward
      @pack_id = pack_id
      @score = score.to_i
      @stars = stars || Stars.call(score: @score)
    end

    def call
      pack = QuizDefinition.catalog.find_pack(@pack_id)
      pack_title = pack.copy(:title)
      url = Rails.application.routes.url_helpers.root_url(rama: @ward.code, host: default_host)
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

      def default_host
        ENV.fetch("APP_HOST", "localhost:3000")
      end
  end
end
