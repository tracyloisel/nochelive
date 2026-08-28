require "test_helper"

class GameDefinitionTest < ActiveSupport::TestCase
  test "loads reyes y profetas with fifteen varied rounds" do
    game = GameDefinition.default
    assert_equal "kings_and_prophets", game.theme.id
    assert_equal 15, game.rounds.size
    assert_includes game.rounds.map(&:type), "buzzer"
    assert_includes game.rounds.map(&:type), "physical_target"
    assert game.find_round("david_goliath").remote_variant.present?
    assert_equal "A", game.find_round("salomon_wisdom").remote_grade
    assert game.find_round("salomon_wisdom").has_choices?
    assert_equal "wisdom", game.find_round("salomon_wisdom").correct_choice
    assert_equal "B", game.find_round("david_goliath").remote_grade
    assert_equal "B", game.find_round("statue_david").remote_grade
    jonah = game.find_round("mime_jonah")
    assert_equal "B", jonah.remote_grade
    assert jonah.story_path?
    assert jonah.matches_path?("storm,fish,shore")
    assert_not jonah.matches_path?("fish,storm,shore")
    assert_equal [ "¡LA TORMENTA!", "¡EL PEZ!", "¡TIERRA!" ], jonah.path_labels("storm,fish,shore")
    assert_equal "B", game.find_round("taboo_nabot").remote_grade
    assert_equal "B", game.find_round("scavenger_harp").remote_grade
    assert game.find_round("scavenger_harp").implemented?
    assert game.find_round("scavenger_harp").scavenger?
    kings = game.find_round("kings_order")
    assert kings.ordering?
    assert kings.implemented?
    assert_equal "A", kings.remote_grade
    assert kings.matches_order?("saul,david,salomon")
    assert_not kings.matches_order?("david,saul,salomon")
    assert_equal %w[Saúl David Salomón], kings.order_labels("saul,david,salomon")
    first = kings.shuffled_items(42)
    assert_equal first, kings.shuffled_items(42)
    assert_equal kings.item_pairs.map { |item| item["key"] }.sort, first.map { |item| item["key"] }.sort
    assert game.find_round("statue_david").implemented?
    assert game.find_round("mime_jonah").story_beats.size == 3
    crown = game.find_round("finale_prophet")
    assert crown.finale?
    assert crown.buzzer?
    assert crown.implemented?
    assert crown.swing?
    assert crown.layered_finale?
    assert_equal "El burger de fuego", crown.title
    assert_equal 4, crown.layers.size
    assert_equal "El pan", crown.layers.first["label"]
    assert_equal "La salsa.", crown.layers.last["text"]
    assert_equal "A", crown.remote_grade
    assert_equal 25, crown.points
    shout = game.find_round("category_prophets")
    assert shout.category?
    assert shout.implemented?
    assert_equal "B", shout.remote_grade
    assert_equal 3, shout.category_goal
    assert_equal 3, shout.matching_names("Elías, Daniel e Isaías").size
    assert_equal 1, shout.matching_names("Daniel").size
    judgment = game.find_round("vote_solomon")
    assert judgment.vote?
    assert judgment.implemented?
    assert_equal "A", judgment.remote_grade
    assert_match(/sabiduría/, judgment.question)
  end

  test "rejects unknown round types" do
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ { "id" => "a", "type" => "quiz", "title" => "A", "points" => 10 } ]
      )
    end
  end

  test "rejects missing theme title duplicate ids and empty rounds" do
    assert_raises(GameDefinition::Error) { GameDefinition.new("theme" => { "id" => "x" }, "rounds" => [ { "id" => "a" } ]) }
    assert_raises(GameDefinition::Error) { GameDefinition.new("theme" => { "id" => "x", "title" => "X" }, "rounds" => []) }
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [
          { "id" => "a", "type" => "buzzer", "title" => "A", "points" => 10 },
          { "id" => "a", "type" => "buzzer", "title" => "B", "points" => 10 }
        ]
      )
    end
  end

  test "category race needs names" do
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ { "id" => "a", "type" => "category_race", "title" => "A", "points" => 10 } ]
      )
    end
  end

  test "freeze dance needs instructions" do
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ { "id" => "a", "type" => "freeze_dance", "title" => "A", "points" => 10 } ]
      )
    end
  end

  test "mime story path needs beats" do
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ {
          "id" => "a", "type" => "mime", "title" => "A", "points" => 10,
          "remote_variant" => { "type" => "story_path" }
        } ]
      )
    end
  end

  test "ordering needs items and order" do
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ { "id" => "a", "type" => "ordering", "title" => "A", "points" => 10 } ]
      )
    end
  end

  test "choice rounds need choices and taboo needs keys" do
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ { "id" => "a", "type" => "true_false", "title" => "A", "points" => 10 } ]
      )
    end
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ { "id" => "a", "type" => "buzzer", "title" => "A", "points" => 10, "question" => "¿Qué?" } ]
      )
    end
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ { "id" => "a", "type" => "taboo", "title" => "A", "points" => 10 } ]
      )
    end
  end

  test "unknown yaml file and unknown round id" do
    assert_raises(GameDefinition::Error) { GameDefinition.load("nope") }
    assert_raises(GameDefinition::Error) { GameDefinition.default.find_round("missing") }
  end

  test "remote grades and tap goal" do
    buzzer = GameDefinition.default.find_round("salomon_wisdom")
    assert buzzer.buzzer?
    assert_equal "A", buzzer.remote_grade
    assert_equal 10, buzzer.tap_goal

    freeze = GameDefinition.default.find_round("freeze_saul")
    assert freeze.freeze?
    assert freeze.implemented?
    assert_equal "B", freeze.remote_grade
    assert_equal "freeze_catch", freeze.remote_type
    assert_equal 2000, freeze.freeze_window

    room_only = GameDefinition.new(
      "theme" => { "id" => "x", "title" => "X" },
      "rounds" => [ { "id" => "a", "type" => "buzzer", "title" => "A", "points" => 10, "remote" => false } ]
    )
    assert_equal "D", room_only.find_round("a").remote_grade
  end

  test "every round points at a story still that exists" do
    GameDefinition.default.rounds.each do |round|
      if round.layered_finale?
        round.layers.each do |layer|
          assert Rails.public_path.join("media/#{layer['image']}").file?, "#{round.id} missing public/media/#{layer['image']}"
          assert Rails.public_path.join("media/#{layer['clip']}").file?, "#{round.id} missing public/media/#{layer['clip']}" if layer["clip"].present?
        end
      else
        rel = round.presentation.fetch("image")
        assert_match(%r{\Astories/.+\.(?:jpg|png)\z}, rel)
        assert Rails.public_path.join("media/#{rel}").file?, "#{round.id} missing public/media/#{rel}"
      end
    end
  end

  test "rejects a finale with fewer than two layers" do
    assert_raises(GameDefinition::Error) do
      GameDefinition.new(
        "theme" => { "id" => "x", "title" => "X" },
        "rounds" => [ {
          "id" => "a", "type" => "finale", "title" => "A", "points" => 25, "swing" => true,
          "layers" => [ { "key" => "pan", "label" => "Pan", "text" => "T", "host" => "H", "picto" => "scroll", "image" => "burger/pan.jpg" } ]
        } ]
      )
    end
  end

  test "swing points catch the leader then sit on the floor" do
    game = GameDefinition.default
    crown = game.find_round("finale_prophet")
    night = game_sessions(:david)
    behind = teams(:casa)
    leader = teams(:leones)
    leader.update!(cached_score: 40)
    behind.update!(cached_score: 0)
    assert_equal 41, crown.swing_points(night, behind)
    assert_equal 25, crown.swing_points(night, leader)
  end

  test "timed rounds start outside the warn ratio" do
    timed = GameDefinition.default.rounds.select { |round| round.duration.to_i.positive? }
    assert timed.any?
    assert_operator timed.map { |round| round.duration.to_i }.min, :>=, 20
    timed.each do |round|
      refute ApplicationController.helpers.play_timer_warn?(round.duration, round.duration), round.id
      refute ApplicationController.helpers.play_timer_hot?(round.duration, round.duration), round.id
    end
  end
end
