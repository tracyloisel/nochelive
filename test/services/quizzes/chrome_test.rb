require "test_helper"

class Quizzes::ChromeTest < ActiveSupport::TestCase
  setup { Quizzes::Chrome.reset! }
  teardown { Quizzes::Chrome.reset! }

  test "ceremony chrome is celestial light glory" do
    chrome = Quizzes::Chrome.ceremony
    assert_equal "light", chrome.mode
    assert_equal "glorious", chrome.atmosphere
    assert_equal "soft", chrome.glass
    assert_equal "media/social/campus-ceremony-friends-v1.png", chrome.image
  end

  test "ceremony chrome celebrates a duel win in Celestial Light" do
    chrome = Quizzes::Chrome.ceremony(outcomes: %i[behind ahead])
    assert_equal "light", chrome.mode
    assert_equal "glorious", chrome.atmosphere
    assert_equal "soft", chrome.glass
    assert_equal "media/social/campus-duel-victory-friends-v1.png", chrome.image
  end

  test "ceremony chrome turns a duel loss into a Celestial Dark rematch" do
    chrome = Quizzes::Chrome.ceremony(outcomes: [:behind])
    assert_equal "dark", chrome.mode
    assert_equal "dramatic", chrome.atmosphere
    assert_equal "strong", chrome.glass
    assert_equal "media/social/campus-duel-rematch-storm-v1.png", chrome.image
  end

  test "eden still is celestial light with soft glass" do
    question = QuizDefinition.catalog.find_question("moises", "eden_adan")
    chrome = Quizzes::Chrome.call(question:)
    assert_equal "light", chrome.mode
    assert_equal "peaceful", chrome.atmosphere
    assert_equal "soft", chrome.glass
  end

  test "red sea still is celestial dark with strong glass" do
    question = QuizDefinition.catalog.find_question("jehova", "mar_rojo")
    chrome = Quizzes::Chrome.call(question:)
    assert_equal "dark", chrome.mode
    assert_equal "dramatic", chrome.atmosphere
    assert_equal "strong", chrome.glass
  end

  test "gethsemane is solemn dark" do
    question = QuizDefinition.catalog.find_question("nazareno", "getsemani")
    chrome = Quizzes::Chrome.call(question:)
    assert_equal "dark", chrome.mode
    assert_equal "solemn", chrome.atmosphere
    assert_equal "strong", chrome.glass
  end

  test "mode_for reads the still catalog without a question" do
    assert_equal "dark", Quizzes::Chrome.mode_for("/media/quizzes/coronas/ungio_david.jpg")
    assert_equal "light", Quizzes::Chrome.mode_for("quizzes/moises/eden_adan.jpg")
    assert_nil Quizzes::Chrome.mode_for("church/worship.jpg")
    assert_nil Quizzes::Chrome.mode_for(nil)
  end

  test "every quiz still has a catalog row with valid tokens" do
    images = QuizDefinition.catalog.all_questions.map { |question| question.presentation["image"] }
    stills = Quizzes::Chrome.stills
    missing = images - stills.keys
    assert_empty missing, "quiz stills missing from catalog: #{missing.join(', ')}"

    stills.each do |image, row|
      assert_includes Quizzes::Chrome::MODES, row["mode"].to_s, image
      assert_includes Quizzes::Chrome::ATMOSPHERES, row["atmosphere"].to_s, image
      assert_includes Quizzes::Chrome::GLASSES, row["glass"].to_s, image
      asset = Frontend::MediaManifest.fetch_source("media/#{image}")
      assert asset, "catalog image missing from responsive manifest: #{image}"
      assert Rails.root.join("media/masters", asset.fetch("source")).file?, "catalog master missing on disk: #{image}"
    end

    assert stills.values.any? { |row| row["mode"] == "light" && row["glass"] == "soft" }
    assert stills.values.any? { |row| row["mode"] == "dark" && row["glass"] == "strong" }
  end

  test "unknown image falls back to light medium" do
    Quizzes::Chrome.stills = {}
    question = QuizDefinition.catalog.all_questions.first
    chrome = Quizzes::Chrome.call(question:)
    assert_equal "light", chrome.mode
    assert_equal "peaceful", chrome.atmosphere
    assert_equal "medium", chrome.glass
  end
end
