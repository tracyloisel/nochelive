require "test_helper"

class Quizzes::WorldTest < ActiveSupport::TestCase
  test "first pack is current for new player" do
    digest = GameSession.digest_token("world-new")
    world = Quizzes::World.call(device_digest: digest)
    assert_equal "coronas", world.current_pack_id
    assert_equal QuizDefinition.catalog.pack_ids.size, world.packs.size
    first = world.packs.first
    assert_equal :current, first.state
    assert world.packs.drop(1).all? { |p| p.state == :locked }
    assert_nil world.path.finished
    assert_equal "coronas", world.path.current.id
    assert_equal :locked, world.path.locked.state
    assert_equal world.packs.second.id, world.path.locked.id
  end

  test "every catalog pack has a map category and tier" do
    world = Quizzes::World.call(device_digest: GameSession.digest_token("world-map-taxonomy"))

    assert world.packs.all? { |pack| pack.category.in?(%w[rois prophetes sagesse heros]) }
    assert world.packs.all? { |pack| Quizzes::World.tier_for(pack.index).present? }
  end

  test "last-days trilogy lives on the prophets path" do
    %w[apocalipsis segunda_venida milenio].each do |pack_id|
      assert_equal "prophetes", Quizzes::World.category_for(pack_id)
    end
  end

  test "the Word of Wisdom is on the wisdom path after inicios" do
    world = Quizzes::World.call(device_digest: GameSession.digest_token("world-dc89"))
    pack = world.packs.find { |candidate| candidate.id == "dc89_word_of_wisdom" }

    assert_equal "sagesse", pack.category
    assert_equal world.packs.index { |candidate| candidate.id == "inicios" } + 1, pack.index
  end

  test "an open run from an archived expedition stays out of the active journey" do
    digest = GameSession.digest_token("world-archived-psalms")
    QuizRun.create!(
      device_digest: digest,
      pack_id: "exp_psalms_disappearing_voice",
      position: 1,
      score: 0,
      status: "open",
      opened_at: Time.current
    )

    world = Quizzes::World.call(device_digest: digest)

    assert_equal "coronas", world.current_pack_id
    refute world.packs.any? { |pack| pack.id == "exp_psalms_disappearing_voice" }
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

  test "query count stays constant as finished packs grow" do
    digest = GameSession.digest_token("world-query-budget")
    QuizDefinition.catalog.pack_ids.first(5).each_with_index do |pack_id, index|
      QuizRun.create!(
        device_digest: digest,
        pack_id:,
        position: QuizDefinition::QUESTIONS_PER_PACK,
        score: 40 + index,
        status: "finished",
        opened_at: Time.current
      )
    end

    assert_operator sql_queries { Quizzes::World.call(device_digest: digest) }, :<=, 2
  end

  private

    def sql_queries(&block)
      count = 0
      callback = lambda do |_name, _start, _finish, _id, payload|
        count += 1 unless payload[:cached] || payload[:name].in?(%w[SCHEMA TRANSACTION])
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
      count
    end
end
