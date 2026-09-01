# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class ExpeditionCouncilContractTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  TEMPLATE = File.join(ROOT, "config/expeditions/_showrunner_template.yml")

  def setup
    @dossier = YAML.safe_load_file(TEMPLATE, aliases: true)
  end

  def test_quiz_ownership_separates_semantics_sequence_and_player_copy
    owners = @dossier.dig("council", "section_owners")

    assert_equal 8, @dossier.fetch("schema_version")
    assert_equal "expedition-spiritual-experience-director", owners.fetch("formation_quizzes.items[].semantic_handoff")
    assert_equal "expedition-game-designer", owners.fetch("packs.items[].repetition_schedule")
    assert_equal "expedition-incarnate-writer", owners.fetch("formation_quizzes.items[].prompt")
    assert_equal "expedition-incarnate-writer", owners.fetch("formation_quizzes.items[].choices[].text")
    assert_equal "expedition-incarnate-writer", owners.fetch("formation_quizzes.items[].correction")
    assert_equal "expedition-incarnate-writer", owners.fetch("formation_quizzes.items[].reader_cta_label")
  end

  def test_quiz_copy_moves_from_human_voice_to_truth_on_one_revision
    quizzes = @dossier.fetch("formation_quizzes")
    workflow = quizzes.fetch("workflow")
    human_voice = @dossier.dig("review", "human_voice_gate", "quiz_copy")
    truth = @dossier.dig("review", "truth_gate", "quiz_copy")

    assert_equal ["human-voice-reviewer", "expedition-fact-checker"], workflow.fetch("reviewers")
    assert_equal ["review.human_voice_gate", "review.truth_gate"], workflow.fetch("rewrite_invalidates")
    assert workflow.fetch("same_copy_revision_required")
    assert human_voice.fetch("same_revision_as_truth_required")
    assert_equal "PASS", truth.fetch("human_voice_status_required")
    assert truth.fetch("same_revision_as_human_voice_required")
    assert_equal human_voice.fetch("reviewed_paths"), truth.fetch("reviewed_paths")
  end

  def test_every_quiz_copy_records_the_three_human_checks
    question = @dossier.dig("formation_quizzes", "items", 0)

    assert_equal "expedition-spiritual-experience-director", question.dig("semantic_handoff", "owner")
    assert_equal "expedition-incarnate-writer", question.dig("copy_handoff", "owner")
    assert_equal(
      %w[human_would_ask_this choices_under_two_seconds reveal_opens_curiosity],
      question.fetch("writer_self_check").keys
    )
    refute question.key?("spaced_repetition"), "real repetition timing belongs only to packs"
  end
end
