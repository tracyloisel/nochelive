require "test_helper"

class Quizzes::WorldTest < ActiveSupport::TestCase
  test "first pack is current for new player" do
    digest = GameSession.digest_token("world-new")
    world = Quizzes::World.call(device_digest: digest)
    assert_equal "coronas", world.current_pack_id
    first = world.packs.first
    assert_equal :current, first.state
    assert world.packs.drop(1).all? { |p| p.state == :locked }
    assert_nil world.path.finished
    assert_equal "coronas", world.path.current.id
    assert_equal :locked, world.path.locked.state
    assert_equal world.packs.second.id, world.path.locked.id
  end

  test "finishing pack unlocks next" do
    digest = GameSession.digest_token("world-finish")
    run = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas").run
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    world = Quizzes::World.call(device_digest: digest)
    assert_equal :finished, world.packs.first.state
    assert_equal :current, world.packs.second.state
    assert_equal world.packs.first.id, world.path.finished.id
    assert_equal :finished, world.path.finished.state
    assert_equal world.packs.second.id, world.path.current.id
    assert_equal :locked, world.path.locked.state
  end
end
