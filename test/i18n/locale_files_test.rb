require "test_helper"

class LocaleFilesTest < ActiveSupport::TestCase
  test "UI locale files share the same keys" do
    trees = {
      "es" => load_locale("es.yml", "es"),
      "en" => load_locale("en.yml", "en"),
      "fr" => load_locale("fr.yml", "fr"),
      "pt-BR" => load_locale("pt-BR.yml", "pt-BR")
    }
    expected = flatten_keys(trees["es"]).sort
    trees.each do |code, tree|
      assert_equal expected, flatten_keys(tree).sort, "#{code} UI keys differ from es"
    end
  end

  test "reader Circle composition and ranking copy is present in every UI locale" do
    circle_keys = %w[
      question_message_label
      ranking_label
      ranking_score
      upvote
      downvote
      reply_ranking_label
      reply_upvote
      reply_downvote
    ]

    %i[es en fr pt-BR].each do |locale|
      I18n.with_locale(locale) do
        circle_keys.each do |key|
          value = I18n.t("scripture_reader.circle.#{key}", score: 3)
          assert value.present?, "#{locale} scripture_reader.circle.#{key}"
          refute_match(/translation missing/i, value)
        end
        assert I18n.exists?("scripture_reader.companion.circle_jump_label", locale), locale.to_s
      end
    end
  end

  test "quiz locale files share the same keys" do
    trees = {
      "en" => load_locale("quizzes.en.yml", "en"),
      "fr" => load_locale("quizzes.fr.yml", "fr"),
      "pt-BR" => load_locale("quizzes.pt-BR.yml", "pt-BR")
    }
    expected = flatten_keys(trees["en"]).sort
    trees.each do |code, tree|
      assert_equal expected, flatten_keys(tree).sort, "#{code} quiz keys differ from en"
    end
  end

  test "parable quiz locale files share the same keys" do
    trees = {
      "en" => load_locale("quizzes.parabolas.en.yml", "en"),
      "fr" => load_locale("quizzes.parabolas.fr.yml", "fr"),
      "pt-BR" => load_locale("quizzes.parabolas.pt-BR.yml", "pt-BR")
    }
    expected = flatten_keys(trees["en"]).sort
    trees.each do |code, tree|
      assert_equal expected, flatten_keys(tree).sort, "#{code} parable quiz keys differ from en"
    end
  end

  test "street combo copy has no score multiplier sign" do
    shouts = %w[quiz.streak_two quiz.streak_three quiz.streak_five quiz.streak_ten]
    %i[es en fr pt-BR].each do |locale|
      I18n.with_locale(locale) do
        line = I18n.t("quiz.combo", count: 3)
        assert line.present?, locale.to_s
        refute_includes line, "×"
        refute_includes line, "x3"
        shouts.each do |key|
          shout = I18n.t(key)
          assert shout.present?, "#{locale} #{key}"
          refute_match(/\bSTRIKE\b/i, shout)
          refute_includes shout, "×"
        end
      end
    end
  end

  test "street praises are a shouted list in every locale" do
    %i[es en fr pt-BR].each do |locale|
      I18n.with_locale(locale) do
        lines = I18n.t("street.praises")
        assert_kind_of Array, lines, locale.to_s
        assert_operator lines.size, :>=, 7, locale.to_s
        assert lines.all? { |line| line.is_a?(String) && line.present? }, locale.to_s
        assert_includes lines, I18n.t("street.praise"), locale.to_s
      end
    end
  end

  private

    def load_locale(filename, root)
      YAML.safe_load_file(Rails.root.join("config/locales/#{filename}"), aliases: true).fetch(root)
    end

    def flatten_keys(value, prefix = nil)
      return [ prefix ] unless value.is_a?(Hash)

      value.flat_map do |key, child|
        next_key = prefix ? "#{prefix}.#{key}" : key.to_s
        flatten_keys(child, next_key)
      end
    end
end
