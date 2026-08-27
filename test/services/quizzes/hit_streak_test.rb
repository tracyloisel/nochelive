require "test_helper"

class Quizzes::HitStreakTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("combo-device")
    @run = Quizzes::Draw.call(device_digest: @digest).run
  end

  test "ask on the first question is idle" do
    combo = Quizzes::HitStreak.call(run: @run)
    assert_equal 0, combo.count
    refute combo.grew
    refute combo.broke
    assert_equal "idle", combo.tier
    assert_nil combo.sfx
    assert_nil combo.shout_key
  end

  test "a hit grows the combo and a miss resets it without extra points" do
    first = @run.question
    Quizzes::Submit.call(run: @run, choice_key: first.correct_choice)
    hit = Quizzes::HitStreak.call(run: @run.reload)
    assert_equal 1, hit.count
    assert hit.grew
    refute hit.broke
    assert_equal "spark", hit.tier
    assert_nil hit.shout_key
    assert_equal first.points, @run.score

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
    refute broken.grew
    assert_equal "idle", broken.tier
    assert_nil broken.shout_key
    assert_equal first.points, @run.score
  end

  test "milestones shout two three five ten without multiplying score" do
    expected = {
      2 => { shout: "two", sfx: nil, tier: "glow" },
      3 => { shout: "three", sfx: "fire_whoosh", tier: "hot" },
      5 => { shout: "five", sfx: "fire_whoosh", tier: "blaze" },
      10 => { shout: "ten", sfx: "chest", tier: "legend" }
    }
    points = 0
    10.times do |index|
      n = index + 1
      question = @run.reload.question
      Quizzes::Submit.call(run: @run, choice_key: question.correct_choice)
      points += question.points
      combo = Quizzes::HitStreak.call(run: @run.reload)
      assert_equal n, combo.count
      assert combo.grew
      if expected[n]
        assert_equal expected[n][:shout], combo.shout_key, "shout at #{n}"
        assert_equal expected[n][:tier], combo.tier, "tier at #{n}"
        if expected[n][:sfx]
          assert_equal expected[n][:sfx], combo.sfx, "sfx at #{n}"
        else
          assert_nil combo.sfx, "sfx at #{n}"
        end
      else
        assert_nil combo.shout_key, "no shout at #{n}"
      end
      Quizzes::Advance.call(run: @run.reload) unless n == 10
    end
    assert_equal points, @run.score
  end

  test "finished run keeps the end combo and max streak" do
    10.times do
      Quizzes::Submit.call(run: @run.reload, choice_key: @run.question.correct_choice)
      Quizzes::Advance.call(run: @run.reload)
    end
    combo = Quizzes::HitStreak.call(run: @run.reload)
    assert @run.finished?
    assert_equal 10, combo.count
    refute combo.grew
    assert_equal "legend", combo.tier
    assert_equal 10, Quizzes::HitStreak.max_count(run: @run)
  end
end
