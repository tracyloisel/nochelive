require "test_helper"

class ScriptureCircleConversationVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @voter = people(:carmen_lopez)
    @root = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Comment recevoir de l’aide dans ce passage ?" }
    )
  end

  test "casts and toggles a conversation vote before returning to its reader thread" do
    sign_in_person(@voter)

    put scripture_circle_conversation_vote_path(conversation_root_id: @root.id), params: {
      conversation_vote: { direction: "up" }
    }

    assert_redirected_to scripture_path("ot/ps/52", locale: "fr", circle: 1, anchor: "circle-post-#{@root.id}")
    assert_equal [ "up" ], votes_for_root.pluck(:direction)

    put scripture_circle_conversation_vote_path(conversation_root_id: @root.id), params: {
      conversation_vote: { direction: "up" }
    }

    assert_response :redirect
    assert_empty votes_for_root
  end

  test "preserves only a known reader sort after a vote" do
    sign_in_person(@voter)

    put scripture_circle_conversation_vote_path(conversation_root_id: @root.id), params: {
      conversation_vote: { direction: "up" },
      circle_sort: "popular"
    }

    assert_redirected_to scripture_path(
      "ot/ps/52", locale: "fr", circle: 1, circle_sort: "popular", anchor: "circle-post-#{@root.id}"
    )

    put scripture_circle_conversation_vote_path(conversation_root_id: @root.id), params: {
      conversation_vote: { direction: "down" },
      circle_sort: "forged-return"
    }

    assert_redirected_to scripture_path("ot/ps/52", locale: "fr", circle: 1, anchor: "circle-post-#{@root.id}")
  end

  test "does not create a self vote and does not disclose another ward's conversation" do
    sign_in_person(@author)

    put scripture_circle_conversation_vote_path(conversation_root_id: @root.id), params: {
      conversation_vote: { direction: "up" }
    }

    assert_response :redirect
    assert_empty votes_for_root

    other_ward = extra_ward(133, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    sign_in_person(outsider, token: "conversation-vote-outsider")

    put scripture_circle_conversation_vote_path(conversation_root_id: @root.id), params: {
      conversation_vote: { direction: "down" }
    }

    assert_response :not_found
    assert_empty votes_for_root
  end

  test "requires a permitted vote direction" do
    sign_in_person(@voter)

    put scripture_circle_conversation_vote_path(conversation_root_id: @root.id), params: {
      conversation_vote: { direction: "sideways" }
    }

    assert_response :redirect
    assert_empty votes_for_root
  end

  private

    def votes_for_root
      ScriptureCircleConversationVote.where(conversation_root: @root)
    end

    def sign_in_person(person, token: "conversation-vote-device")
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
