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
      assert_equal "#{delivery.destination}?nl_delivery=#{delivery.id}", payload.dig(:data, :path)
      assert_match %r{\A/notifications/receipts/}, payload.dig(:data, :receipt_path)
    end
  end

  test "invitation push names the friend and never promises a fixed pack" do
    invitation = duel_invitations(:named_pili_invitation)
    delivery = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:carmen_phone_push),
      person: people(:carmen_garcia),
      kind: "duel_invitation",
      dedupe_key: "invitation-content-test",
      subject: invitation,
      destination: "/desafio/#{invitation.public_token}",
      status: "queued"
    )

    Locale::AVAILABLE.each do |locale|
      delivery.web_push_subscription.update!(locale:)
      payload = Notifications::Content.call(delivery.reload)

      assert_includes payload[:body], people(:pili).given_name, locale
      pack_title = I18n.with_locale(locale) { QuizDefinition.catalog.find_pack("coronas").copy(:title) }
      refute_includes payload[:body], pack_title, locale
      assert_match %r{\A/desafio/}, payload.dig(:data, :path), locale
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

  test "night reminders are localized and open the exact session entrance" do
    night = game_sessions(:elias)
    delivery = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:carmen_phone_push),
      person: people(:carmen_garcia), kind: "night_starting_soon",
      dedupe_key: "night-content-test", subject: night,
      destination: Rails.application.routes.url_helpers.night_path(night.code), status: "queued"
    )

    Locale::AVAILABLE.each do |locale|
      delivery.web_push_subscription.update!(locale:)
      payload = Notifications::Content.call(delivery.reload)

      assert payload[:title].present?, locale
      assert payload[:body].include?(night.starts_at.in_time_zone("Europe/Madrid").strftime("%H:%M")), locale
      refute_match(/translation missing/i, payload.values_at(:title, :body).join(" "), locale)
      assert_equal "/s/#{night.code}?nl_delivery=#{delivery.id}", payload.dig(:data, :path)
    end
  end
end
