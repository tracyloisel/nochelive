require "test_helper"

class ErrorPagesTest < ActiveSupport::TestCase
  ERROR_PAGES = {
    "400" => "400.html",
    "404" => "404.html",
    "406" => "406-unsupported-browser.html",
    "422" => "422.html",
    "500" => "500.html"
  }.freeze

  test "static error pages keep their recovery path when Rails is unavailable" do
    ERROR_PAGES.each do |status, filename|
      document = Nokogiri::HTML5(File.read(Rails.root.join("public", filename)))

      assert_equal "noindex,nofollow", document.at_css('meta[name="robots"]')["content"], filename
      assert_equal status, document.at_css(".error-code").text.strip, filename
      assert_equal "/", document.at_css(".primary-action")["href"], filename
      assert_equal "/error-pages.css?v=1", document.at_css('link[rel="stylesheet"]')["href"], filename
      assert_equal "/error-pages.js?v=2", document.at_css("script[defer]")["src"], filename
      assert document.at_css('[data-locale="fr"]'), filename

      document.css("[data-copy]").each do |node|
        %w[es pt-BR fr en].each do |locale|
          assert node["data-#{locale.downcase}"].present?, "#{filename}: missing #{locale} copy"
        end
      end
    end
  end

  test "error artwork is optimized and available outside the asset pipeline" do
    %w[celestial-wayfinding-4xx-v1.webp celestial-restoration-5xx-v1.webp].each do |filename|
      path = Rails.root.join("public/media/errors", filename)

      assert path.exist?, filename
      assert_operator path.size, :<, 250.kilobytes, filename
    end
  end
end
