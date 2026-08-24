require "test_helper"

class Answers::SubmitTest < ActiveSupport::TestCase
  setup do
    @round = round_runs(:salomon)
    @team = teams(:leones)
    @player = players(:lucia)
  end

  test "submit is idempotent for a team" do
    @round.lock!
    one = Answers::Submit.call(round: @round, team: @team, player: @player, body: "Sabiduría")
    two = Answers::Submit.call(round: @round, team: @team, player: @player, body: "Otra")
    assert_equal one.id, two.id
    assert_equal "Sabiduría", one.reload.body
  end

  test "rejects answers when the round is closed" do
    @round.reveal!
    assert_raises(RuntimeError) do
      Answers::Submit.call(round: @round, team: @team, player: @player, body: "Sabiduría")
    end
  end

  test "buzzer round only accepts the answering team" do
    Buzz.accept!(round_run: @round, team: @team, player: @player)
    @round.lock!
    assert_raises(RuntimeError) do
      Answers::Submit.call(round: @round, team: teams(:casa), player: players(:daniel), body: "No")
    end
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
    Answers::Submit.call(round:, team: teams(:casa), player: players(:daniel), body: "Elías, Daniel, Isaías")
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote category miss does not auto score" do
    round = round_runs(:category_prophets)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: teams(:casa), player: players(:daniel), body: "Daniel")
    assert_not teams(:casa).reload.score_events.where(round_run: round).exists?
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
    Answers::Submit.call(round:, team: teams(:casa), player: players(:daniel), body: "storm,fish,shore")
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote mime wrong path is incorrect" do
    round = round_runs(:mime_jonah)
    round.update!(phase: "open")
    Answers::Submit.call(round:, team: teams(:casa), player: players(:daniel), body: "shore,fish,storm")
    assert teams(:casa).reload.score_events.where(kind: "incorrect", round_run: round).exists?
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
    Answers::Submit.call(round:, team: teams(:casa), player: players(:daniel), body: "david,saul,salomon")
    assert teams(:casa).reload.score_events.where(kind: "incorrect", round_run: round).exists?
    assert_not teams(:casa).score_events.where(kind: "correct", round_run: round).exists?
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
