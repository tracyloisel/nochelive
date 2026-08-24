require "test_helper"

class GameSessionTest < ActiveSupport::TestCase
  test "podium ranks by score and names the champion" do
    night = create_night
    leones = add_team(night, name: "Leones", emblem: "leon")
    casa = add_team(night, name: "Casa", emblem: "ola")
    add_player(night, name: "Lucía", team: leones)
    add_player(night, name: "Daniel", team: casa)
    leones.update!(cached_score: 40)
    casa.update!(cached_score: 18)

    assert_equal [ leones, casa ], night.podium_teams
    assert_equal leones, night.champion
    assert_equal 1, night.place_for(leones)
    assert_equal 2, night.place_for(casa)
    assert_equal [ casa, leones ], night.visual_podium
    assert_not night.tied_finale?
  end

  test "tied first place is a shared crown" do
    night = create_night
    leones = add_team(night, name: "Leones")
    profetas = add_team(night, name: "Profetas", emblem: "fuego")
    leones.update!(cached_score: 20)
    profetas.update!(cached_score: 20)

    assert night.tied_finale?
    assert_nil night.champion
    assert_equal 1, night.place_for(leones)
    assert_equal 1, night.place_for(profetas)
  end

  test "start playing opens the first pending round" do
    night = game_sessions(:elias)
    night.start_playing!
    assert night.playing?
    assert_equal "intro", round_runs(:lobby_first).reload.phase
  end

  test "start playing does not intro a later round when one is already live" do
    night = create_night
    first, second = night.round_runs.order(:position).first(2)
    first.update!(phase: "open", opened_at: Time.current)

    night.start_playing!

    assert night.playing?
    assert_equal "open", first.reload.phase
    assert_equal "pending", second.reload.phase
  end

  test "pause resume and finish" do
    night = game_sessions(:david)
    night.pause!
    assert night.paused?
    night.resume!
    assert night.playing?
    night.finish!
    assert night.finished?
    assert_equal "completed", round_runs(:salomon).reload.phase
  end

  test "generates a word or a five-character code" do
    20.times do
      code = GameSession.generate_code
      assert code.in?(GameSession::CODE_WORDS) || code.match?(/\A[A-Z2-9]{5}\z/)
    end
  end

  test "retries when the session code collides" do
    codes = [ "DAVID", "ABCDE" ]
    original = GameSession.method(:generate_code)
    GameSession.define_singleton_method(:generate_code) { codes.shift }
    night = GameSession.start!(ward: wards(:blank))
    assert_equal "ABCDE", night.code
    assert_equal 15, night.round_runs.count
  ensure
    GameSession.define_singleton_method(:generate_code, original)
  end

  test "maps the english theme id to the yaml file" do
    night = game_sessions(:david)
    night.theme_id = "kings_and_prophets"
    assert_equal "reyes_y_profetas", night.theme_file_id
  end

  test "three team visual podium" do
    night = create_night
    first = add_team(night, name: "A")
    second = add_team(night, name: "B", emblem: "ola")
    third = add_team(night, name: "C", emblem: "fuego")
    first.update!(cached_score: 30)
    second.update!(cached_score: 20)
    third.update!(cached_score: 10)
    assert_equal [ second, first, third ], night.visual_podium
  end

  test "single team podium and nil place" do
    night = game_sessions(:cerrada)
    assert_equal [ teams(:campeones) ], night.visual_podium
    assert_nil night.place_for(nil)
  end

  test "normalize_code strips junk" do
    assert_equal "DAVID", GameSession.normalize_code(" da-vid ")
  end

  test "broadcast_state delegates to Nights::Broadcast" do
    assert_nothing_raised { game_sessions(:david).broadcast_state }
  end

  test "digest names the holder" do
    night = game_sessions(:david)
    assert_not night.presenter_held_by?("phone")
    Presenters::Seat.call(night:, device_token: "phone")
    assert night.reload.presenter_held_by?("phone")
    assert_not night.presenter_held_by?("other")
    assert_not night.presenter_held_by?("")
  end

  test "live nights exclude finished ones" do
    assert_includes GameSession.live, game_sessions(:david)
    assert_includes GameSession.live, game_sessions(:elias)
    assert_not_includes GameSession.live, game_sessions(:cerrada)
  end
end
