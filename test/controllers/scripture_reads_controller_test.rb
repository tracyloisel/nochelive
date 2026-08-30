require "test_helper"

class ScriptureReadsControllerTest < ActionDispatch::IntegrationTest
  test "records one qualified read per device and returns the confirmed label" do
    assert_difference("ScriptureChapterRead.count", 1) do
      post scripture_reads_path, params: { reference: "ot/1-sam/16" }, as: :json
    end

    assert_response :success
    payload = response.parsed_body
    assert_equal true, payload.fetch("counted")
    assert_equal 1, payload.fetch("reads_count")
    assert_equal "1 lectura", payload.fetch("label")

    assert_no_difference("ScriptureChapterRead.count") do
      post scripture_reads_path, params: { reference: "ot/1-sam/16" }, as: :json
    end
    assert_response :success
    assert_equal false, response.parsed_body.fetch("counted")
    assert_equal 1, response.parsed_body.fetch("reads_count")
  end

  test "returns a native localized count" do
    patch locale_path, params: { locale: "fr" }
    post scripture_reads_path, params: { reference: "ot/1-sam/16" }, as: :json

    assert_response :success
    assert_equal "1 lecture", response.parsed_body.fetch("label")
  end

  test "rejects a reference unavailable in the reader" do
    assert_no_difference([ "ScriptureChapterRead.count", "ScriptureChapterStat.count" ]) do
      post scripture_reads_path, params: { reference: "ot/gen/99" }, as: :json
    end

    assert_response :unprocessable_entity
  end
end
