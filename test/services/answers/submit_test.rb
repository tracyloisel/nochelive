require "test_helper"

class Answers::SubmitTest < ActiveSupport::TestCase
  setup do
    @round = round_runs(:salomon)
    @team = teams(:leones)
    @player = players(:lucia)
  end

  test "submit is idempotent for a team" do
    @round.lock!
    one = Answers::Submit.call(round: @round, team: @team, player: @player, body: "wisdom")
    two = Answers::Submit.call(round: @round, team: @team, player: @player, body: "riches")
    assert_equal one.id, two.id
    assert_equal "wisdom", one.reload.body
  end

  test "rejects answers when the round is closed" do
    @round.reveal!
    assert_raises(RuntimeError) do
      Answers::Submit.call(round: @round, team: @team, player: @player, body: "Sabiduría")
    end
  end

  test "buzzer round only accepts the answering team in the chapel" do
    Buzz.accept!(round_run: @round, team: @team, player: @player)
    @round.lock!
    TeamMembership.create!(player: players(:ana), team: teams(:casa))
    assert_raises(RuntimeError) do
      Answers::Submit.call(round: @round, team: teams(:casa), player: players(:ana), body: "No")
    end
  end

  test "remote answers a buzzer QCM while the round is open" do
    home = teams(:daniel_home)
    Answers::Submit.call(round: @round, team: home, player: players(:daniel), body: "wisdom")
    assert home.reload.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "room cannot answer a buzzer round before lock" do
    assert_raises(RuntimeError) do
      Answers::Submit.call(round: @round, team: @team, player: @player, body: "wisdom")
    end
  end

  test "buzzer QCM auto scores the chosen key" do
    Buzz.accept!(round_run: @round, team: @team, player: @player)
    @round.lock!
    Answers::Submit.call(round: @round, team: @team, player: @player, body: "wisdom")
    assert @team.reload.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "buzzer QCM miss is incorrect" do
    Buzz.accept!(round_run: @round, team: @team, player: @player)
    @round.lock!
    Answers::Submit.call(round: @round, team: @team, player: @player, body: "riches")
    assert @team.reload.score_events.where(kind: "incorrect", round_run: @round).exists?
  end

  test "ordering awards correct for the true sequence" do
    round = round_runs(:kings_order)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: @team, player: @player, body: "saul,david,salomon")
    assert @team.reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote category awards correct for three names" do
    round = round_runs(:category_prophets)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: teams(:daniel_home), player: players(:daniel), body: "Elías, Daniel, Isaías")
    assert teams(:daniel_home).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote category miss does not auto score" do
    round = round_runs(:category_prophets)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: teams(:daniel_home), player: players(:daniel), body: "Daniel")
    assert_not teams(:daniel_home).reload.score_events.where(round_run: round).exists?
  end

  test "room category slam does not auto score" do
    round = round_runs(:category_prophets)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: @team, player: @player, body: "¡Ya!")
    assert @team.reload.answers.where(round_run: round).exists?
    assert_not @team.score_events.where(round_run: round).exists?
  end

  test "remote mime awards the lived path" do
    round = round_runs(:mime_jonah)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: teams(:daniel_home), player: players(:daniel), body: "storm,fish,shore")
    assert teams(:daniel_home).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote mime wrong path is incorrect" do
    round = round_runs(:mime_jonah)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: teams(:daniel_home), player: players(:daniel), body: "shore,fish,storm")
    assert teams(:daniel_home).reload.score_events.where(kind: "incorrect", round_run: round).exists?
  end

  test "room mime slam does not auto score" do
    round = round_runs(:mime_jonah)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: @team, player: @player, body: "¡Ya!")
    assert @team.reload.answers.where(round_run: round).exists?
    assert_not @team.score_events.where(round_run: round).exists?
  end

  test "ordering awards incorrect for a wrong sequence" do
    round = round_runs(:kings_order)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: teams(:daniel_home), player: players(:daniel), body: "david,saul,salomon")
    event = teams(:daniel_home).reload.score_events.find_by!(kind: "incorrect", round_run: round)
    assert_equal 0, event.points
    assert_equal 0, event.xp
    assert_equal 0, teams(:daniel_home).cached_score
    assert_not teams(:daniel_home).score_events.where(kind: "correct", round_run: round).exists?
  end

  test "scavenger first shout pulses found once" do
    round = round_runs(:scavenger_harp)
    round.update!(phase: "open")
    pulses = capture_pulses(round.game_session) do
      Answers::Submit.call(round:, team: @team, player: @player, body: "¡Lo tenemos!")
      Answers::Submit.call(round:, team: @team, player: @player, body: "otra")
    end
    assert_equal [ "found", nil ], pulses.map { |pulse| pulse&.fetch(:kind, nil) }
  end

  test "room category slam pulses shout" do
    round = round_runs(:category_prophets)
    round.update!(phase: "open")
    pulses = capture_pulses(round.game_session) do
      Answers::Submit.call(round:, team: @team, player: @player, body: "¡Ya!")
    end
    assert_equal [ "shout" ], pulses.map { |pulse| pulse&.fetch(:kind, nil) }
  end

  private

  def capture_pulses(_night)
    pulses = []
    original = GameSession.instance_method(:broadcast_state)
    GameSession.define_method(:broadcast_state) { |pulse: nil| pulses << pulse }
    yield
    pulses
  ensure
    GameSession.define_method(:broadcast_state, original)
  end
end
