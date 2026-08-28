require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "new asks only for a first name and never for a code" do
    get night_name_path(@night.code)
    assert_response :success
    assert_select "body.is-night-entry.is-celestial-dark"
    assert_select "#night_join.night-entry"
    assert_select ".night-entry-panel"
    assert_select "a.quiet-link", text: /Soy el presentador/
    assert_select "button[type=submit]", text: I18n.t("join.enter_play")
    assert_select "a.night-entry-watch"
    assert_select "input[name=name]", count: 1
    assert_select "input[name*=code]", count: 0
    assert_select ".play-reel", count: 0
    assert_select ".gate", count: 0
    assert_select ".picto-btn", count: 0
  end

  test "create participant then refresh does not clone" do
    assert_difference -> { @night.players.count }, 1 do
      post night_players_path(@night.code), params: { name: "Carlos", location: "room" }
    end
    assert_redirected_to night_play_path(@night.code)
    assert_no_difference -> { @night.players.count } do
      get night_name_path(@night.code)
    end
    assert_redirected_to night_play_path(@night.code)
  end

  test "create spectator" do
    post night_players_path(@night.code), params: { name: "TV", role: "spectator" }
    assert_redirected_to night_public_path(@night.public_token)
    assert_no_difference -> { @night.players.count } do
      get night_public_path(@night.public_token)
    end
    get night_name_path(@night.code)
    assert_response :success
  end

  test "invalid name" do
    post night_players_path(@night.code), params: { name: "" }
    assert_response :unprocessable_entity
  end

  test "joining creates an ephemeral guest without profile friction" do
    assert_difference -> { @night.players.count }, 1 do
      post night_players_path(@night.code), params: { name: "Carlos", location: "room" }
    end
    player = @night.players.order(:id).last
    assert_nil player.person_id
    assert_equal "Carlos", player.name
  end

  test "a homonym enters immediately without a disambiguation form" do
    post night_players_path(@night.code), params: {
      name: "Carmen",
      avatar_key: "gato",
      favorite_year: 1492,
      location: "room"
    }
    assert_redirected_to night_play_path(@night.code)
    assert_nil @night.players.order(:id).last.person_id
  end

  test "optional legacy profile fields do not block the guest" do
    post night_players_path(@night.code), params: {
      name: "Carmen",
      family_name: "Ruiz",
      avatar_key: "gato",
      favorite_year: 1492,
      location: "room",
      soy_nueva: "1"
    }
    assert_redirected_to night_play_path(@night.code)
    player = @night.players.order(:id).last
    assert_equal "Carmen", player.name
    assert_nil player.person_id
  end

  test "remote player is seated alone" do
    post night_players_path(@night.code), params: { name: "Carlos", location: "remote" }
    assert_redirected_to night_play_path(@night.code)
    player = @night.players.order(:id).last
    assert player.remote?
    assert_nil player.person_id
    assert player.team.solo?
    assert_equal "Carlos", player.team.name
  end
end
