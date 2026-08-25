require "test_helper"

class LocaleTest < ActiveSupport::TestCase
  test "casts known tags and Portuguese variants" do
    assert_equal "es", Locale.cast("es")
    assert_equal "fr", Locale.cast("fr")
    assert_equal "en", Locale.cast("en-US")
    assert_equal "pt-BR", Locale.cast("pt")
    assert_equal "pt-BR", Locale.cast("pt_BR")
    assert_equal "es", Locale.cast("de")
  end

  test "maps each locale to a flag picto" do
    assert_equal "flag-es", Locale.flag("es")
    assert_equal "flag-pt", Locale.flag("pt-BR")
    assert_equal "flag-fr", Locale.flag("fr")
    assert_equal "flag-en", Locale.flag("en-US")
  end

  test "reads Accept-Language in order" do
    assert_equal "fr", Locale.from_accept_language("fr-FR,fr;q=0.9,en;q=0.8")
    assert_equal "pt-BR", Locale.from_accept_language("pt-BR,pt;q=0.9")
    assert_equal "es", Locale.from_accept_language("de,ja;q=0.8")
    assert_equal "en", Locale.from_accept_language("de,en-US;q=0.8")
  end
end
