require "test_helper"

class ScriptureHighlightsControllerTest < ActionDispatch::IntegrationTest
  test "saves a localized highlight on the current profile only once" do
    person = create_street_profile!(name: "Lectora")
    payload = {
      highlight: {
        reference: "ot/1-sam/16",
        locale: "fr",
        start_verse: 1,
        end_verse: 2,
        start_offset: 2,
        end_offset: 14,
        selected_text: "  dit   l’Éternel à Samuel  "
      }
    }

    assert_difference("person.scripture_highlights.count", 1) do
      post scripture_highlights_path, params: payload, as: :json
    end

    assert_response :created
    assert_equal person.scripture_highlights.last.id, response.parsed_body.fetch("id")
    assert_equal 1, response.parsed_body.fetch("start_verse")
    assert_equal 14, response.parsed_body.fetch("end_offset")
    assert_equal "fr", person.scripture_highlights.last.locale
    assert_equal "dit l’Éternel à Samuel", person.scripture_highlights.last.selected_text

    assert_no_difference("person.scripture_highlights.count") do
      payload[:highlight][:selected_text] = "L’Éternel parla à Samuel"
      post scripture_highlights_path, params: payload, as: :json
    end
    assert_response :created
    assert_equal "L’Éternel parla à Samuel", person.scripture_highlights.last.reload.selected_text
  end

  test "requires a current profile" do
    assert_no_difference("ScriptureHighlight.count") do
      post scripture_highlights_path, params: {
        highlight: {
          reference: "ot/1-sam/16",
          locale: "fr",
          start_verse: 1,
          end_verse: 1,
          start_offset: 0,
          end_offset: 8
        }
      }, as: :json
    end

    assert_response :unauthorized
  end

  test "rejects an invalid scripture reference" do
    create_street_profile!(name: "Lectora")

    assert_no_difference("ScriptureHighlight.count") do
      post scripture_highlights_path, params: {
        highlight: {
          reference: "unknown/book/1",
          locale: "fr",
          start_verse: 1,
          end_verse: 1,
          start_offset: 0,
          end_offset: 8
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "removes a highlight owned by the current profile" do
    person = create_street_profile!(name: "Lectora")
    highlight = person.scripture_highlights.create!(
      reference: "ot/1-sam/16",
      locale: "fr",
      start_verse: 1,
      end_verse: 2,
      start_offset: 2,
      end_offset: 14
    )

    assert_difference("person.scripture_highlights.count", -1) do
      delete scripture_highlight_path(highlight), as: :json
    end

    assert_response :no_content
  end

  test "does not remove another profile's highlight" do
    owner = people(:pili)
    highlight = owner.scripture_highlights.create!(
      reference: "ot/1-sam/16",
      locale: "fr",
      start_verse: 1,
      end_verse: 1,
      start_offset: 2,
      end_offset: 14
    )
    create_street_profile!(name: "Lectora")

    assert_no_difference("owner.scripture_highlights.count") do
      delete scripture_highlight_path(highlight), as: :json
    end

    assert_response :not_found
  end
end
