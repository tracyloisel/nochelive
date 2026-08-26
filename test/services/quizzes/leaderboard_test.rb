require "test_helper"

class Quizzes::LeaderboardTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:blank)
    @pili = @ward.people.create!(given_name: "Pili", avatar_key: "gato", favorite_year: 2018)
    @carmen = @ward.people.create!(given_name: "Carmen", avatar_key: "perro", favorite_year: 2019)
  end

  test "ranks the best pack score per person in the ward" do
    QuizRun.create!(
      device_digest: "leader-a",
      person: @pili,
      pack_id: "placas",
      position: 10,
      score: 50,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "leader-b",
      person: @carmen,
      pack_id: "placas",
      position: 10,
      score: 80,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "leader-c",
      person: @pili,
      pack_id: "placas",
      position: 10,
      score: 60,
      status: "finished",
      opened_at: Time.current
    )

    board = Quizzes::Leaderboard.call(ward: @ward, pack_id: "placas", person: @pili, limit: 5)

    assert_equal 2, board.rows.size
    assert_equal @carmen, board.rows.first.person
    assert_equal 80, board.rows.first.score
    assert_equal 2, board.your_rank
    assert_equal 60, board.your_score
    assert board.rows.second.you
  end

  test "totals best pack scores across the ward" do
    QuizRun.create!(
      device_digest: "total-a",
      person: @pili,
      pack_id: "placas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "total-b",
      person: @pili,
      pack_id: "milagros",
      position: 10,
      score: 30,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "total-c",
      person: @carmen,
      pack_id: "placas",
      position: 10,
      score: 90,
      status: "finished",
      opened_at: Time.current
    )

    board = Quizzes::Leaderboard.call(ward: @ward, person: @pili, limit: 5)

    assert_equal 90, board.rows.first.score
    assert_equal @carmen, board.rows.first.person
    assert_equal 70, board.your_score
    assert_equal 2, board.your_rank
  end

  test "limits visible rows and paginates large wards" do
    ward = wards(:blank)
    people = Array.new(12) do |index|
      ward.people.create!(
        given_name: "Jugador#{index}",
        avatar_key: Player::AVATARS[index % Player::AVATARS.size],
        favorite_year: 2000 + index
      )
    end
    people.each_with_index do |person, index|
      QuizRun.create!(
        device_digest: "bulk-#{index}",
        person:,
        pack_id: "placas",
        position: 10,
        score: index + 1,
        status: "finished",
        opened_at: Time.current
      )
    end
    target = people[3]

    first_page = Quizzes::Leaderboard.call(ward:, person: target, limit: 5, offset: 0)
    second_page = Quizzes::Leaderboard.call(ward:, person: target, limit: 5, offset: 5)

    assert_equal 5, first_page.rows.size
    assert_equal 12, first_page.players
    assert_equal 1, first_page.page
    assert_equal 3, first_page.pages
    assert_equal 1, first_page.rows.first.rank
    assert_equal 5, second_page.rows.size
    assert_equal 2, second_page.page
    assert_equal 6, second_page.rows.first.rank
    assert_equal 9, first_page.your_rank
    assert_equal 2, first_page.your_page
    assert_equal 2, second_page.your_page
  end

  test "include_you adds context row when player is outside the top slice" do
    ward = wards(:blank)
    people = Array.new(8) do |index|
      ward.people.create!(
        given_name: "Runner#{index}",
        avatar_key: Player::AVATARS[index % Player::AVATARS.size],
        favorite_year: 2010 + index
      )
    end
    people.each_with_index do |person, index|
      QuizRun.create!(
        device_digest: "ctx-#{index}",
        person:,
        pack_id: "placas",
        position: 10,
        score: (index + 1) * 10,
        status: "finished",
        opened_at: Time.current
      )
    end
    target = people[2]

    board = Quizzes::Leaderboard.call(ward:, person: target, limit: 3, include_you: true)

    assert_equal 4, board.rows.size
    assert_equal 6, board.your_rank
    assert board.rows.last.you
    assert board.rows.last.context
    assert_equal 30, board.rows.last.score
  end

  test "filters by name prefix without loading every ward member" do
    ward = wards(:blank)
    ana = ward.people.create!(given_name: "Ana", avatar_key: "gato", favorite_year: 2018)
    andres = ward.people.create!(given_name: "Andrés", avatar_key: "perro", favorite_year: 2019)
    pablo = ward.people.create!(given_name: "Pablo", avatar_key: "loro", favorite_year: 2020)
    [ ana, andres, pablo ].each_with_index do |person, index|
      QuizRun.create!(
        device_digest: "name-#{index}",
        person:,
        pack_id: "placas",
        position: 10,
        score: 40 + index,
        status: "finished",
        opened_at: Time.current
      )
    end

    board = Quizzes::Leaderboard.call(ward:, limit: 10, q: "An")

    assert_equal 2, board.rows.size
    assert_equal [ "Andrés", "Ana" ], board.rows.map { |row| row.person.given_name }
  end

  test "marks a person live from a recent device heartbeat" do
    QuizRun.create!(
      device_digest: "live-a",
      person: @pili,
      pack_id: "placas",
      position: 10,
      score: 50,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "live-b",
      person: @carmen,
      pack_id: "placas",
      position: 10,
      score: 80,
      status: "finished",
      opened_at: Time.current
    )
    PersonDevice.create!(person: @carmen, device_token: "live-carmen", last_seen_at: Time.current)
    PersonDevice.create!(person: @pili, device_token: "stale-pili", last_seen_at: 2.minutes.ago)

    board = Quizzes::Leaderboard.call(ward: @ward, pack_id: "placas", person: @pili, limit: 5)

    assert board.rows.first.live
    assert_not board.rows.second.live
    assert_not board.your_live
  end

  test "counts lifetime answers across packs, open runs, and a pack filter" do
    placas = QuizRun.create!(
      device_digest: "ans-placas",
      person: @pili,
      pack_id: "placas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    milagros = QuizRun.create!(
      device_digest: "ans-milagros",
      person: @pili,
      pack_id: "milagros",
      position: 10,
      score: 20,
      status: "finished",
      opened_at: Time.current
    )
    open_run = QuizRun.create!(
      device_digest: "ans-open",
      person: @pili,
      pack_id: "coronas",
      position: 2,
      score: 0,
      status: "open",
      opened_at: Time.current
    )
    carmen_run = QuizRun.create!(
      device_digest: "ans-carmen",
      person: @carmen,
      pack_id: "placas",
      position: 10,
      score: 90,
      status: "finished",
      opened_at: Time.current
    )
    record_answers(placas, 3)
    record_answers(milagros, 2)
    record_answers(open_run, 1, choice_key: nil)
    record_answers(carmen_run, 4)

    board = Quizzes::Leaderboard.call(ward: @ward, person: @pili, limit: 5)
    pack_board = Quizzes::Leaderboard.call(ward: @ward, pack_id: "placas", person: @pili, limit: 5)

    pili_row = board.rows.find { |row| row.person == @pili }
    carmen_row = board.rows.find { |row| row.person == @carmen }
    assert_equal 6, pili_row.answered
    assert_equal 4, carmen_row.answered
    assert_equal 6, board.your_answered
    assert_equal 6, pack_board.rows.find { |row| row.person == @pili }.answered
    assert_equal 6, pack_board.your_answered
  end

  test "pack_best_totals without a ward sums the world" do
    other = extra_ward(12, country_code: "BR", country_name: "Brazil")
    rival = other.people.create!(given_name: "Joao", avatar_key: "gato", favorite_year: 1994)
    QuizRun.create!(
      device_digest: "world-rival",
      person: rival,
      pack_id: "placas",
      position: 10,
      score: 44,
      status: "finished",
      opened_at: Time.current
    )
    carmen = people(:carmen_garcia)
    world = Quizzes::Leaderboard.pack_best_totals
    demo = Quizzes::Leaderboard.pack_best_totals(ward: wards(:demo))

    assert_equal 120 + 88, world[carmen.id]
    assert_equal 44, world[rival.id]
    assert_equal 120 + 88, demo[carmen.id]
    refute_includes demo.keys, rival.id
    assert_equal world[carmen.id], demo[carmen.id]
  end

  test "your_answered is present when the player sits off the page" do
    people = Array.new(6) do |index|
      @ward.people.create!(
        given_name: "Fila#{index}",
        avatar_key: Player::AVATARS[index % Player::AVATARS.size],
        favorite_year: 2001 + index
      )
    end
    people.each_with_index do |person, index|
      QuizRun.create!(
        device_digest: "off-#{index}",
        person:,
        pack_id: "placas",
        position: 10,
        score: 80 - index,
        status: "finished",
        opened_at: Time.current
      )
    end
    pili_run = QuizRun.create!(
      device_digest: "off-pili",
      person: @pili,
      pack_id: "placas",
      position: 10,
      score: 1,
      status: "finished",
      opened_at: Time.current
    )
    record_answers(pili_run, 7)

    board = Quizzes::Leaderboard.call(ward: @ward, person: @pili, limit: 3)

    assert_nil(board.rows.find { |row| row.you })
    assert_equal 7, board.your_answered
    assert_equal 7, board.your_rank
  end

  private

    def record_answers(run, count, choice_key: "a")
      count.times do |index|
        QuizAnswer.create!(
          quiz_run: run,
          device_digest: run.device_digest,
          pack_id: run.pack_id,
          question_id: "q-#{run.id}-#{index}",
          choice_key:,
          correct: choice_key.present?
        )
      end
    end
end
