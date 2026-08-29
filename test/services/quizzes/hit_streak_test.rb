require "test_helper"

class Quizzes::HitStreakTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("combo-device")
    @run = Quizzes::Draw.call(device_digest: @digest).run
  end

  test "ask on the first question is idle" do
    combo = Quizzes::HitStreak.call(run: @run)
    assert_equal 0, combo.count
    assert_equal 0, combo.broken_count
    refute combo.grew
    refute combo.broke
    assert_equal "idle", combo.tier
    assert_nil combo.sfx
    assert_nil combo.shout_key
  end

  test "a hit grows the combo and a miss banks earned points" do
    first = @run.question
    Quizzes::Submit.call(run: @run, choice_key: first.correct_choice)
    hit = Quizzes::HitStreak.call(run: @run.reload)
    assert_equal 1, hit.count
    assert hit.grew
    refute hit.broke
    assert_equal "spark", hit.tier
    assert_equal "start", hit.shout_key
    assert_equal 5, @run.score

    Quizzes::Advance.call(run: @run.reload)
    asking = Quizzes::HitStreak.call(run: @run.reload)
    assert_equal 1, asking.count
    refute asking.grew
    assert_equal "spark", asking.tier
    assert_nil asking.shout_key

    miss = (@run.question.choices.map { |choice| choice["key"] } - [ @run.question.correct_choice ]).first
    Quizzes::Submit.call(run: @run, choice_key: miss)
    broken = Quizzes::HitStreak.call(run: @run.reload)
    assert_equal 0, broken.count
    assert broken.broke
    assert_equal 1, broken.broken_count
    refute broken.grew
    assert_equal "idle", broken.tier
    assert_nil broken.shout_key
    assert_equal 5, @run.score
  end

  test "milestones narrate the streak while the bonus grows to its cap" do
    expected = {
      1 => { shout: "start", sfx: nil, tier: "spark" },
      2 => { shout: "two", sfx: nil, tier: "glow" },
      3 => { shout: "three", sfx: nil, tier: "hot" },
      4 => { shout: "four", sfx: nil, tier: "hot" },
      5 => { shout: "five", sfx: nil, tier: "blaze" },
      6 => { shout: nil, sfx: nil, tier: "blaze" },
      7 => { shout: nil, sfx: nil, tier: "blaze" },
      8 => { shout: nil, sfx: nil, tier: "blaze" },
      9 => { shout: nil, sfx: nil, tier: "blaze" },
      10 => { shout: "ten", sfx: nil, tier: "legend" }
    }
    gains = []
    10.times do |index|
      n = index + 1
      question = @run.reload.question
      Quizzes::Submit.call(run: @run, choice_key: question.correct_choice)
      gains << @run.reload.quiz_answers.find_by!(question_id: question.id).points_awarded
      combo = Quizzes::HitStreak.call(run: @run.reload)
      assert_equal n, combo.count
      assert combo.grew
      row = expected[n]
      if row
        if row[:shout]
          assert_equal row[:shout], combo.shout_key, "shout at #{n}"
        else
          assert_nil combo.shout_key, "no shout at #{n}"
        end
        assert_equal row[:tier], combo.tier, "tier at #{n}"
        assert_nil combo.sfx, "streak stays silent at #{n}"
      else
        assert_nil combo.shout_key, "no shout at #{n}"
        assert_nil combo.sfx, "no streak sfx at #{n}"
      end
      Quizzes::Advance.call(run: @run.reload) unless n == 10
    end
    assert_equal [ 5, 7, 8, 9, 10, 10, 10, 10, 10, 10 ], gains
    assert_equal 89, @run.score
  end

  test "finished run keeps the end combo and max streak" do
    10.times do
      Quizzes::Submit.call(run: @run.reload, choice_key: @run.question.correct_choice)
      Quizzes::Advance.call(run: @run.reload)
    end
    combo = Quizzes::HitStreak.call(run: @run.reload)
    assert @run.finished?
    assert_equal 10, combo.count
    assert_equal 0, combo.broken_count
    refute combo.grew
    assert_equal "legend", combo.tier
    assert_equal 10, Quizzes::HitStreak.max_count(run: @run)
  end
end
