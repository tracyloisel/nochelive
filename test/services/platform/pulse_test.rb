require "test_helper"

class Platform::PulseTest < ActiveSupport::TestCase
  setup do
    QuizAnswer.delete_all
  end

  test "counts this month's answers and players including guests" do
    carmen = quiz_runs(:carmen_coronas)
    guest = quiz_runs(:crowd_milagros)
    QuizAnswer.create!(
      quiz_run: carmen,
      device_digest: carmen.device_digest,
      pack_id: carmen.pack_id,
      question_id: "pulse-carmen",
      choice_key: "a",
      correct: true,
      created_at: Time.zone.local(2026, 8, 10, 12)
    )
    QuizAnswer.create!(
      quiz_run: guest,
      device_digest: guest.device_digest,
      pack_id: guest.pack_id,
      question_id: "pulse-guest",
      choice_key: "b",
      correct: false,
      created_at: Time.zone.local(2026, 8, 12, 12)
    )
    QuizAnswer.create!(
      quiz_run: carmen,
      device_digest: carmen.device_digest,
      pack_id: carmen.pack_id,
      question_id: "pulse-old",
      choice_key: "c",
      correct: true,
      created_at: Time.zone.local(2026, 7, 20, 12)
    )

    travel_to Time.zone.local(2026, 8, 26, 18) do
      pulse = Platform::Pulse.call

      assert_equal 2, pulse.questions
      assert_equal 2, pulse.players
      assert_equal 0, pulse.online
      assert_equal Ward.listed.count, pulse.wards
    end
  end

  test "counts a ficha once even with two answers" do
    carmen = quiz_runs(:carmen_coronas)
    2.times do |n|
      QuizAnswer.create!(
        quiz_run: carmen,
        device_digest: carmen.device_digest,
        pack_id: carmen.pack_id,
        question_id: "pulse-twice-#{n}",
        choice_key: "a",
        correct: true
      )
    end

    pulse = Platform::Pulse.call

    assert_equal 2, pulse.questions
    assert_equal 1, pulse.players
  end

  test "online unites street devices and night seats without double-counting a ficha" do
    mark_person_online(people(:pili))
    lucia = players(:lucia)
    lucia.update!(person_id: people(:pili).id)
    mark_player_online(lucia.reload)

    pulse = Platform::Pulse.call

    assert_equal 1, pulse.online
  end

  test "online counts a night guest without a ficha" do
    mark_player_online(players(:lucia))

    pulse = Platform::Pulse.call

    assert_equal 1, pulse.online
  end
end
