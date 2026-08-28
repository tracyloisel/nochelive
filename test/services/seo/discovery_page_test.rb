require "test_helper"

class Seo::DiscoveryPageTest < ActiveSupport::TestCase
  test "resolves every page in every locale" do
    Seo::DiscoveryPage.all.each do |key|
      I18n.available_locales.each do |locale|
        options = Seo::DiscoveryPage.path_options(key, locale)
        page = Seo::DiscoveryPage.resolve(locale: options[:locale], slug: options[:slug])

        assert page, "expected #{key} in #{locale}"
        assert_equal key, page.key
        assert_equal locale, page.locale
      end
    end
  end

  test "rejects invented or mismatched localized slugs" do
    assert_nil Seo::DiscoveryPage.resolve(locale: "fr", slug: "juegos-biblicos")
    assert_nil Seo::DiscoveryPage.resolve(locale: "fr", slug: "ceci-n-existe-pas")
  end
end
