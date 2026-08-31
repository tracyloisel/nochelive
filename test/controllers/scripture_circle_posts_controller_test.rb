require "test_helper"

class ScriptureCirclePostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @responder = people(:carmen_lopez)
  end

  test "preserves a known reader sort after publishing a root or a reply" do
    sign_in_person(@author)

    post scripture_circle_posts_path, params: {
      post: {
        reference: "ot/ps/52",
        kind: "question",
        locale: "fr",
        body: "Comment puis-je revenir à cette parole demain ?"
      },
      circle_sort: "unresolved"
    }

    root = @author.scripture_circle_posts.order(:id).last
    assert_redirected_to scripture_path(
      "ot/ps/52", locale: "fr", circle: 1, circle_event_post: root.id,
      circle_sort: "unresolved", circle_event: "published"
    )

    sign_in_person(@responder, token: "circle-reply-sort")
    post scripture_circle_posts_path, params: {
      post: {
        reference: "ot/ps/52",
        kind: "reply",
        locale: "fr",
        parent_id: root.id,
        body: "Je te partage une réponse simple pour aujourd’hui."
      },
      circle_sort: "popular"
    }

    reply = @responder.scripture_circle_posts.order(:id).last
    assert_redirected_to scripture_path(
      "ot/ps/52", locale: "fr", circle: 1, circle_event_post: reply.id,
      circle_sort: "popular", circle_event: "replied"
    )
  end

  test "does not retain an unrecognized reader sort after publishing" do
    sign_in_person(@author)

    post scripture_circle_posts_path, params: {
      post: {
        reference: "ot/ps/52",
        kind: "reflection",
        locale: "fr",
        body: "Je garde une pensée paisible de ce chapitre."
      },
      circle_sort: "untrusted"
    }

    created = @author.scripture_circle_posts.order(:id).last
    assert_redirected_to scripture_path(
      "ot/ps/52", locale: "fr", circle: 1, circle_event_post: created.id, circle_event: "published"
    )
  end

  private

    def sign_in_person(person, token: "circle-post-sort")
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
