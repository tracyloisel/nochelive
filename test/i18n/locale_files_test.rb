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

  test "game locale files share the same keys" do
    trees = {
      "en" => load_locale("games.en.yml", "en"),
      "fr" => load_locale("games.fr.yml", "fr"),
      "pt-BR" => load_locale("games.pt-BR.yml", "pt-BR")
    }
    expected = flatten_keys(trees["en"]).sort
    trees.each do |code, tree|
      assert_equal expected, flatten_keys(tree).sort, "#{code} game keys differ from en"
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

  test "game copy follows the request locale" do
    round = GameDefinition.default.find_round("salomon_wisdom")
    I18n.with_locale(:es) do
      assert_match(/Salomón/, round.copy(:title))
    end
    I18n.with_locale(:en) do
      assert_equal "Solomon's choice", round.copy(:title)
      assert_equal "Wisdom", round.choice_copy({ "key" => "wisdom", "label" => "Sabiduría" })
    end
    I18n.with_locale(:fr) do
      assert_equal "Le choix de Salomon", round.copy(:title)
    end
    I18n.with_locale(:"pt-BR") do
      assert_equal "A escolha de Salomão", round.copy(:title)
    end
  end

  test "guess keys include every locale so mixed nights still match" do
    round = GameDefinition.default.find_round("category_prophets")
    keys = round.all_guess_keys.map { |key| ActiveSupport::Inflector.transliterate(key).downcase }
    assert_includes keys, "isaiah"
    assert_includes keys, "elie"
    assert_includes keys, "elias"
    assert round.matches_guess?("Isaiah, Élie")
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
