require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "new asks for a name" do
    get night_name_path(@night.code)
    assert_response :success
    assert_select "a.quiet-link", text: /Soy el presentador/
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
    assert_redirected_to night_watch_path(@night.code)
    get night_name_path(@night.code)
    assert_redirected_to night_watch_path(@night.code)
  end

  test "invalid name" do
    post night_players_path(@night.code), params: { name: "" }
    assert_response :unprocessable_entity
  end

  test "guest join still works with only a name" do
    assert_difference -> { @night.players.count }, 1 do
      post night_players_path(@night.code), params: { name: "Carlos", location: "room" }
    end
    player = @night.players.order(:id).last
    assert_nil player.person_id
  end

  test "saving a ficha asks which carmen" do
    post night_players_path(@night.code), params: {
      name: "Carmen",
      avatar_key: "gato",
      favorite_year: 1492,
      location: "room"
    }
    assert_response :unprocessable_entity
    assert_select "h1", "¿Eres una de estas?"
    assert_select ".person-pick", minimum: 2
  end

  test "registering a new carmen with apellido creates a ficha" do
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
    assert_equal "Ruiz", player.person.family_name
  end

  test "remote guest is seated alone" do
    post night_players_path(@night.code), params: { name: "Carlos", location: "remote" }
    assert_redirected_to night_play_path(@night.code)
    player = @night.players.order(:id).last
    assert player.remote?
    assert player.team.solo?
    assert_equal "Carlos", player.team.name
  end
end
