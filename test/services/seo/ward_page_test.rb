require "test_helper"

class Seo::WardPageTest < ActiveSupport::TestCase
  test "uses the persisted slug for every localized path" do
    ward = wards(:demo)

    assert_equal "benidorm", Seo::WardPage.slug(ward)
    assert_equal(
      { locale: "es", ward_section: "santos-de-los-ultimos-dias", slug: "benidorm" },
      Seo::WardPage.path_options(ward, :es)
    )
    assert_equal(
      { locale: "fr", ward_section: "saints-des-derniers-jours", slug: "benidorm" },
      Seo::WardPage.path_options(ward, :fr)
    )
    assert_equal(
      { locale: "en", ward_section: "latter-day-saints", slug: "benidorm" },
      Seo::WardPage.path_options(ward, :en)
    )
    assert_equal(
      { locale: "pt-br", ward_section: "santos-dos-ultimos-dias", slug: "benidorm" },
      Seo::WardPage.path_options(ward, :"pt-BR")
    )
  end

  test "resolves a listed ward by its unique persisted slug" do
    ward = extra_ward(7, listed: true, city: "São Paulo", name: "Capão Redondo Branch", public_slug: "sao-paulo-capao-redondo")

    assert_equal ward, Seo::WardPage.resolve("São Paulo Capão Redondo")
    assert_nil Seo::WardPage.resolve("capao-redondo")
    assert_nil Seo::WardPage.resolve(wards(:blank).public_slug)
  end
end
