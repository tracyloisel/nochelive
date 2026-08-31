require "test_helper"

module Scriptures
  class QuizRecommendationTest < ActiveSupport::TestCase
    test "recommends the curated pack and counts only questions from the chapter" do
      world = Struct.new(:packs).new([
        Quizzes::World::PackView.new(id: "simbolos_mormon", state: :current)
      ])

      recommendation = QuizRecommendation.call(
        reference: "bofm/alma/32",
        world:,
        locale: :fr
      )

      assert_equal "simbolos_mormon", recommendation.pack_id
      assert_equal "Symboles du Livre de Mormon", recommendation.title
      assert_equal 3, recommendation.question_count
      assert_equal :current, recommendation.state
    end

    test "does not suggest a quiz without an exact chapter reference" do
      world = Struct.new(:packs).new(QuizDefinition.catalog.pack_ids.map do |pack_id|
        Quizzes::World::PackView.new(id: pack_id, state: :available)
      end)

      assert_nil QuizRecommendation.call(reference: "scripture/without/quiz", world:)
    end
  end
end
