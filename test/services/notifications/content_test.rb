require "test_helper"

class Notifications::ContentTest < ActiveSupport::TestCase
  test "localizes duel payloads in every supported player language" do
    delivery = notification_deliveries(:carmen_duel_result)
    subscription = delivery.web_push_subscription

    Locale::AVAILABLE.each do |locale|
      subscription.update!(locale:)
      payload = Notifications::Content.call(delivery.reload)

      assert payload[:title].present?, locale
      assert payload[:body].present?, locale
      refute_match(/translation missing/i, payload.values_at(:title, :body).join(" "), locale)
      assert_equal "/desafio/#{delivery.subject.token}?nl_delivery=#{delivery.id}", payload.dig(:data, :path)
    end
  end

  test "daily verse destinations exist and retain the requested language" do
    Notifications::VerseCatalog.entries.each do |entry|
      Locale::AVAILABLE.each do |locale|
        reference = entry.reference(locale)
        destination = entry.destination(locale)

        assert reference.citation.present?, "#{entry.id} #{locale}"
        assert destination.start_with?("/"), "#{entry.id} #{locale}"
        url_locale = locale == "pt-BR" ? "pt-br" : locale
        assert destination.start_with?("/#{url_locale}/"), "#{entry.id} #{locale}"
      end
    end
  end
end
