require "test_helper"

class ScriptureCirclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @viewer = people(:pili)
    @author = people(:carmen_garcia)
  end

  test "redirects the legacy bare reference contract into its reader chapter" do
    sign_in_person(@viewer)

    get scripture_circle_path(reference: "ot/ps/52")

    assert_redirected_to scripture_path("ot/ps/52", locale: I18n.locale, circle: 1)
  end

  test "renders the current ward inbox with shared chrome and ignores a forged ward parameter" do
    local_question = publish_question(
      person: @author,
      body: "Comment puis-je relire ce passage avec plus de paix ?"
    )
    other_ward = extra_ward(95, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Autre", avatar_key: "delfin", locale: "fr")
    foreign_thread = other_ward.scripture_circle_threads.create!(reference: "ot/ps/52")
    foreign_thread.scripture_circle_posts.create!(
      ward: other_ward,
      person: outsider,
      kind: "question",
      locale: "fr",
      body: "Cette question d’une autre rama ne doit jamais apparaître."
    )
    sign_in_person(@viewer)

    get scripture_circle_path(ward_id: other_ward.id)

    assert_response :success
    assert_select "section#circle_index.circle-page[data-controller~='circle-feed']", count: 1
    assert_select "main#circle_index", count: 0
    assert_select "header.quiz-hud", count: 1
    assert_select "nav.navigation-dock", count: 1
    assert_select "turbo-cable-stream-source[channel='Turbo::StreamsChannel']", count: 1
    assert_select "turbo-frame#circle_live_feed", count: 1
    assert_select "turbo-frame#circle_results", count: 0
    assert_select "aside#circle_inbox.circle-inbox", count: 1
    assert_select "section#circle_thread.circle-thread", count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{local_question.id}']", count: 1
    assert_select "form.circle-thread-compose-form[data-turbo-frame='circle_live_feed']", count: 1
    assert_select "textarea#circle-reply-#{local_question.id}[rows='4']", count: 1
    assert_select "button.circle-thread-send", count: 1
    assert_select "a.circle-reader-link[href='#{scripture_path("ot/ps/52")}']", count: 1
    assert_select "a.circle-reader-link[href*='circle_post']", count: 0
    assert_select ".circle-card-link, .circle-desktop-rail, .circle-reading-rail", count: 0
    assert_select "body", text: /autre rama ne doit jamais apparaître/, count: 0
  end

  test "keeps anonymous author identity out of the inbox and preserves the pure reader destination" do
    anonymous_question = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: {
        kind: "question",
        locale: "fr",
        body: "Puis-je demander de l’aide sans afficher mon prénom ?",
        author_visibility: "anonymous_to_ward"
      }
    )
    sign_in_person(@viewer)

    get scripture_circle_path(conversation: anonymous_question.id)

    assert_response :success
    assert_select "a.circle-inbox-row-link[href*='conversation=#{anonymous_question.id}']", count: 1
    assert_select "#circle-message-#{anonymous_question.id} strong", text: I18n.t("scripture_reader.circle.anonymous"), count: 1
    assert_select "body", text: @author.display_name, count: 0
    assert_select "#circle-message-#{anonymous_question.id} img", count: 0
    assert_select "a.circle-reader-link[href='#{scripture_path("ot/ps/52")}']", count: 1
    assert_select "a.circle-reader-link[href*='circle_post']", count: 0
  end

  test "serves the complete inbox workspace in the live feed Turbo frame" do
    question = publish_question(person: @author, body: "Quelle parole puis-je offrir ici ?")
    sign_in_person(@viewer)

    get scripture_circle_path(view: "all", conversation: question.id), headers: { "Turbo-Frame" => "circle_live_feed" }

    assert_response :success
    assert_select "turbo-frame#circle_live_feed", count: 1
    assert_select "turbo-frame#circle_results", count: 0
    assert_select "a.circle-inbox-tab.is-active[href='#{scripture_circle_path(view: "all")}'] > span", text: I18n.t("scripture_circle.filters.all"), count: 1
    assert_select "a.circle-inbox-row-link[data-turbo-frame='circle_live_feed'][href*='conversation=#{question.id}']", count: 1
    assert_select "section#circle_thread .circle-thread-message#circle-message-#{question.id}", count: 1
    assert_select "form.circle-thread-compose-form[data-turbo-frame='circle_live_feed']", count: 1
  end

  test "merges help and recent exchanges while retaining the personal filter" do
    question = publish_question(person: @author, body: "Quelle parole puis-je offrir ici ?")
    recent = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Cette réflexion peut être lue ensemble." }
    )
    mine = ScriptureCircles::Publish.call(
      person: @viewer,
      reference: "bofm/alma/32",
      attributes: { kind: "reflection", locale: "fr", body: "Je partage aussi cette pensée avec la rama." }
    )
    sign_in_person(@viewer)

    get scripture_circle_path(view: "all")

    assert_response :success
    assert_select "a.circle-inbox-tab", count: 2
    assert_select "a.circle-inbox-tab.is-active > span", text: I18n.t("scripture_circle.filters.all"), count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{question.id}']", count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{recent.id}']", count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{mine.id}']", count: 1
    assert_select ".circle-overview-card, .circle-section-action", count: 0

    # Links created before the merge still resolve to the unified list.
    get scripture_circle_path(view: "recent")

    assert_response :success
    assert_select "a.circle-inbox-tab.is-active > span", text: I18n.t("scripture_circle.filters.all"), count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{question.id}']", count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{recent.id}']", count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{mine.id}']", count: 1

    get scripture_circle_path(view: "mine")

    assert_response :success
    assert_select "a.circle-inbox-tab.is-active > span", text: I18n.t("scripture_circle.filters.mine"), count: 1
    assert_select "a.circle-inbox-row-link", count: 1
    assert_select "a.circle-inbox-row-link[href*='conversation=#{mine.id}']", count: 1
  end

  test "fails closed for guests and a disabled Circle" do
    get scripture_circle_path
    assert_response :forbidden

    sign_in_person(@viewer)
    @ward.update!(scripture_circle_mode: "disabled")
    get scripture_circle_path
    assert_response :forbidden
  end

  private

    def publish_question(person:, body:)
      ScriptureCircles::Publish.call(
        person:,
        reference: "ot/ps/52",
        attributes: { kind: "question", locale: "fr", body: }
      )
    end

    def sign_in_person(person, token: "circle-index-device")
      person.person_devices.find_or_create_by!(device_token: token)
      set_signed_cookie(:noche_device, token)
      set_signed_cookie(:noche_ward, person.ward_id)
      set_signed_cookie(:noche_street_person, person.id)
    end

    def set_signed_cookie(name, value)
      signed_value = signed_cookie_jar.tap { |jar| jar.signed[name] = value }[name]
      uri = URI("http://#{host}/")
      cookies.merge("#{name}=#{Rack::Utils.escape(signed_value)}; path=/", uri)
    end

    def signed_cookie_jar(values = {})
      ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, values)
    end
end
