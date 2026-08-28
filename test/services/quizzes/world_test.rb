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

  test "an open challenge run is playable even if the pack is still locked on the map" do
    digest = GameSession.digest_token("world-challenge-open")
    Quizzes::StartPack.call(device_digest: digest, pack_id: "placas", challenge: true)
    world = Quizzes::World.call(device_digest: digest)
    placas = world.packs.find { |pack| pack.id == "placas" }
    assert_equal :open, placas.state
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
