require "test_helper"

class ScriptureCirclePostVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @voter = people(:carmen_lopez)
    @root = publish(person: @author, kind: "question", body: "Que nous apprend cette parole ?")
    @reply = publish(person: @author, kind: "reply", parent: @root, body: "Elle m’aide à choisir l’essentiel.")
  end

  test "casts and toggles a reply vote before returning to the open Circle" do
    sign_in_person(@voter)

    put scripture_circle_post_vote_path(post_id: @reply.id), params: {
      post_vote: { direction: "up" }, circle_sort: "popular"
    }

    assert_redirected_to scripture_path("ot/ps/52", locale: "fr", circle: 1, circle_sort: "popular", anchor: "circle-post-#{@reply.id}")
    assert_equal [ "up" ], ScriptureCirclePostVote.where(scripture_circle_post: @reply).pluck(:direction)

    put scripture_circle_post_vote_path(post_id: @reply.id), params: { post_vote: { direction: "up" } }
    assert_response :redirect
    assert_empty ScriptureCirclePostVote.where(scripture_circle_post: @reply)
  end

  test "does not expose another ward's reply or accept a self vote" do
    sign_in_person(@author)
    put scripture_circle_post_vote_path(post_id: @reply.id), params: { post_vote: { direction: "up" } }
    assert_response :redirect
    assert_empty ScriptureCirclePostVote.where(scripture_circle_post: @reply)

    other_ward = extra_ward(136, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    sign_in_person(outsider, token: "post-vote-outsider")
    put scripture_circle_post_vote_path(post_id: @reply.id), params: { post_vote: { direction: "down" } }
    assert_response :not_found
  end

  private

    def publish(person:, kind:, body:, parent: nil)
      ScriptureCircles::Publish.call(
        person:, reference: "ot/ps/52",
        attributes: { kind:, locale: "fr", parent_id: parent&.id, body: }
      )
    end

    def sign_in_person(person, token: "post-vote-device")
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
