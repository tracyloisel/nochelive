# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class ExpeditionFastContractTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  DOCUMENTATION = File.join(ROOT, "docs/EXPEDITION_FAST.md")
  TEMPLATE = File.join(ROOT, "config/expeditions/_fast_template.yml")
  EXPEDITION_TEMPLATE = File.join(ROOT, "config/expeditions/_fast_expedition_template.yml")
  SHOWRUNNER_TEMPLATE = File.join(ROOT, "config/expeditions/_showrunner_template.yml")
  DOCTRINE_AND_COVENANTS_89 = File.join(ROOT, "config/expeditions/doctrine-et-alliances-89-fast.yml")
  NOCHE_ART = File.join(ROOT, ".agents/skills/noche-art/SKILL.md")
  MEMORY_KEYS = %w[influenceur mystique nouveau_baptise quiz voix mise_en_scene_visuelle direction_artistique critique_deux_secondes localisateur_voix].freeze
  PROMPTS = {
    "influenceur" => "mystique",
    "mystique" => "nouveau-baptise",
    "nouveau-baptise" => "quiz",
    "quiz" => "voix"
  }.freeze

  def test_documentation_requires_a_shared_yaml_memory
    contract = File.read(DOCUMENTATION, encoding: "UTF-8")

    assert_includes contract, "STATUT : FAST ÉDITORIAL COMPLET"
    assert_includes contract, "Aucun agent ne termine avec une simple annonce"
    assert_includes contract, "attend sa réponse complète"
    assert_match(/mêle des questions sur les paroles\s+ou la structure du texte avec des questions de discernement dans la vie/, contract)
    assert_includes contract, "n'obéit à aucun quota numérique"
    assert_includes contract, "config/expeditions/<id>-fast.yml"
    assert_includes contract, "fast.agent_memory"
    assert_includes contract, "production: |-"
    assert_includes contract, "fast.visual_requirements"
    assert_includes contract, "fast.quiz_copy_limits"
    assert_includes contract, "génération"
    assert_includes contract, "72 graphèmes"
    assert_includes contract, "32 graphèmes"
    assert_includes contract, "120 graphèmes"
    assert_includes contract, "390 × 667"
    assert_includes contract, "plusieurs `vrai_faux`"
    assert_includes contract, "## 1 — Responsable du travail missionnaire"
    assert_includes contract, "## 7 — Directeur de mise en scène visuelle"
    assert_includes contract, "## 8 — Directeur artistique-producteur"
    assert_includes contract, "## 9 — Critique des deux secondes"
    assert_includes contract, "## 11 — Localisateur-Voix multilingue"
    assert_includes contract, "fast.source_scope_approval"
    assert_includes contract, "BLOCKED_MISSING_SOURCE"
    assert_includes contract, "source_library"
    assert_includes contract, "iconic_symbol"
    assert_includes contract, "cinematic_realism"
    assert_includes contract, "biblical_illustration"
    assert_includes contract, "visual_proof_approval"
    assert_includes contract, "french_quiz_approval"
    assert_includes contract, "fast.human_quiz_revision.questions"
    assert_includes contract, "fast.result.revision_pipeline"
    assert_includes contract, "Boucle canonique d'amendement humain"
    assert_includes contract, "fast.translation_gate.translation_authorized"
    assert_includes contract, "fast.translation_approval"
    assert_includes contract, "displayed_correct_letter"
    assert_includes contract, "test/system/expedition_fast_voice_visual_test.rb"
    assert_match(/Avant toute traduction/, contract)
    assert_includes contract, "temple de Salt Lake City"
    assert_includes contract, "médias publics officiels de l'Église"
    assert_includes contract, "remplacer entièrement l'ancien Conseil"
    refute_includes contract, "avant de lancer le Conseil"
  end

  def test_missionary_lead_proposes_one_to_three_journeys_and_stops_for_human_scope_approval
    agent_prompts("responsable-missionnaire").each do |path|
      prompt = File.read(path, encoding: "UTF-8")

      assert_match(/venir ou\s+revenir à Jésus-Christ/, prompt, path)
      assert_includes prompt, "se préparent peut-être au baptême", path
      assert_includes prompt, "ne sont pas revenus à l'église depuis longtemps", path
      assert_includes prompt, "Royaume de Dieu", path
      assert_includes prompt, "plan de salut", path
      assert_match(/vie\s+éternelle/, prompt, path)
      assert_includes prompt, "entre une et trois architectures", path
      assert_includes prompt, "Ne fabrique jamais", path
      assert_match(/pourquoi ce nombre de propositions\s+est juste/, prompt, path)
      assert_includes prompt, "fast.agent_memory.responsable_missionnaire", path
      assert_includes prompt, "fast.result.missionary_source_map", path
      assert_includes prompt, "fast.result.missionary_architectures", path
      assert_includes prompt, "fast.source_scope_approval", path
      assert_includes prompt, "awaiting_human_selection", path
      assert_includes prompt, "_fast_expedition_template.yml", path
      assert_includes prompt, "<expedition-id>-fast/packs/<pack-id>.yml", path
      assert_match(/ne contient\s+jamais leurs mémoires Influenceur/, prompt, path)
      assert_includes prompt, "BLOCKED_AMBIGUOUS_SOURCE_APPROVAL", path
      assert_includes prompt, "expedition-fast-influenceur", path
      assert_includes prompt, "attends son retour complet", path
      assert_includes prompt, "fast.visual_requirements", path
      assert_match(/ne produis ni image ni prompt visuel/, prompt, path)
    end
  end

  def test_first_four_agents_wait_for_the_next_stage_in_both_formats
    PROMPTS.each do |stage, next_stage|
      agent_prompts(stage).each do |path|
        prompt = File.read(path, encoding: "UTF-8")

        assert_includes prompt, "expedition-fast-#{next_stage}", path
        assert_includes prompt, "attends", path
        assert_match(/ne\s+termine\s+jamais/, prompt.downcase, path)
      end
    end
  end

  def test_quiz_agent_requires_the_ten_complete_questions_in_both_formats
    agent_prompts("quiz").each do |path|
      prompt = File.read(path, encoding: "UTF-8")

      assert_match(/exactement dix questions (complètes|structurées)/, prompt, path)
      assert_includes prompt, "les types `texte` et `vie`", path
      assert_includes prompt, "sans quota numérique imposé", path
      assert_match(/plusieurs\s+`vrai_faux`/, prompt, path)
      assert_match(/Un\s+`qcm` possède quatre choix/, prompt, path)
      assert_includes prompt, "exactement deux choix", path
      assert_includes prompt, "fast.result.quiz.format_mix", path
      assert_includes prompt, "fast.agent_memory.quiz", path
      assert_includes prompt, "fast.result.quiz.questions", path
      assert_includes prompt, "fast.human_quiz_revision", path
      assert_includes prompt, "fast.result.revision_pipeline.quiz", path
      assert_match(/ne modifie jamais la zone humaine/i, prompt, path)
      assert_includes prompt, "un instantané complet, jamais un patch", path
      assert_match(/l'égalité doit être exacte/, prompt, path)
    end
  end

  def test_voice_agent_is_a_game_show_writer_with_a_mobile_copy_gate
    agent_prompts("voix").each do |path|
      prompt = File.read(path, encoding: "UTF-8")

      assert_includes prompt, "fast.result.quiz.questions", path
      assert_includes prompt, "fast.agent_memory.voix", path
      assert_includes prompt, "fast.result.quiz_final.questions", path
      assert_includes prompt, "fast.human_quiz_revision", path
      assert_includes prompt, "fast.result.revision_pipeline.quiz.processed_revision", path
      assert_includes prompt, "fast.result.revision_pipeline.voix.processed_revision", path
      assert_includes prompt, "expedition-fast-directeur-mise-en-scene", path
      assert_includes prompt, "Auteur de plateau", path
      assert_includes prompt, "présentateur de jeu télévisé", path
      assert_includes prompt, "écris d'abord pour l'oreille", path
      assert_includes prompt, "fast.result.influenceur", path
      assert_includes prompt, "fast.result.mystique", path
      assert_includes prompt, "fast.result.nouveau_baptise", path
      assert_includes prompt, "après une réponse juste comme après une réponse fausse", path
      assert_includes prompt, "Un `vrai_faux` conserve deux choix", path
      assert_includes prompt, "correct_choice", path
      assert_includes prompt, "72 graphèmes", path
      assert_includes prompt, "32 graphèmes", path
      assert_includes prompt, "120 graphèmes", path
      assert_includes prompt, "390 × 667", path
      assert_includes prompt, "REJECT_COPY_OVERFLOW", path
      assert_includes prompt, "à voix haute", path
      assert_includes prompt, "unverified", path
      assert_includes prompt, "QuizDefinition::Question", path
      assert_match(/remplacement de texte dans le DOM/, prompt, path)
      assert_match(/une seule ligne de révélation est marquée juste/, prompt, path)
      assert_includes prompt, "fast.french_quiz_approval", path
      assert_match(/Aucun contenu `es`, `en` ou `pt-BR`/, prompt, path)
      refute_includes prompt, "raccourcir uniquement", path
    end
  end

  def test_localizer_voice_agent_produces_three_native_proven_locales
    agent_prompts("localisateur-voix").each do |path|
      prompt = File.read(path, encoding: "UTF-8")

      assert_includes prompt, "fast.french_quiz_approval.status: approved", path
      assert_includes prompt, "fast.translation_gate.translation_authorized: true", path
      assert_includes prompt, "fast.result.quiz_final.questions", path
      assert_includes prompt, "Produis séparément `es`, `en` et `pt-BR`", path
      assert_includes prompt, "REJECT_NON_NATIVE_VOICE", path
      assert_includes prompt, "correct_choice", path
      assert_includes prompt, "72 graphèmes", path
      assert_includes prompt, "32 graphèmes", path
      assert_includes prompt, "120 graphèmes", path
      assert_includes prompt, "390 × 667", path
      assert_includes prompt, "QuizDefinition::Question", path
      assert_match(/remplacement de texte dans le DOM/, prompt, path)
      assert_includes prompt, "fast.agent_memory.localisateur_voix", path
      assert_includes prompt, "fast.result.translations.es", path
      assert_includes prompt, "fast.translation_approval", path
      assert_match(/aucune génération, retouche, variante/, prompt, path)
      assert_match(/ne .*runtime/im, prompt, path)
    end
  end

  def test_visual_staging_agent_resolves_sources_and_stops_before_generation
    agent_prompts("directeur-mise-en-scene").each do |path|
      prompt = File.read(path, encoding: "UTF-8")

      assert_includes prompt, "source.readings", path
      assert_includes prompt, "Un prompt de Quiz n'est pas une source", path
      assert_includes prompt, "source_library", path
      assert_includes prompt, "source_basis_ids", path
      assert_includes prompt, "BLOCKED_MISSING_SOURCE", path
      assert_includes prompt, "blocked_missing_semantic_content", path
      assert_includes prompt, "REJECT_TWO_SECOND_READ", path
      assert_includes prompt, "Sacrifice de cœur", path
      assert_match(/Ce qui\s+est\s+abandonné doit rester désirable/, prompt, path)
      assert_includes prompt, "iconic_symbol", path
      assert_includes prompt, "human_dramaturgy", path
      assert_includes prompt, "historical_cinematic", path
      assert_includes prompt, "environmental_world", path
      assert_match(/Aucun mode ne possède de supériorité morale/, prompt, path)
      assert_includes prompt, "alternative dramaturgique", path
      assert_includes prompt, "Garde la porte", path
      assert_includes prompt, "approach_comparison", path
      assert_includes prompt, "cinematic_realism", path
      assert_includes prompt, "biblical_illustration", path
      assert_includes prompt, "visual_treatment", path
      assert_match(/costumes.*riches|costumes, coiffures, matières et accessoires\s+riches/m, prompt, path)
      assert_includes prompt, "Une scène historique saisit", path
      assert_includes prompt, "160 mots", path
      assert_includes prompt, "fast.agent_memory.mise_en_scene_visuelle", path
      assert_includes prompt, "visual_concepts", path
      assert_includes prompt, "fast.human_quiz_revision", path
      assert_includes prompt, "fast.result.revision_pipeline.voix.processed_revision", path
      assert_includes prompt, "invalidation.visual_concept_ids", path
      assert_includes prompt, "visual_batch_authorization", path
      assert_includes prompt, "generation_authorized: false", path
      assert_includes prompt, "status: ready_for_proof", path
      assert_includes prompt, "direction_artistique", path
      assert_includes prompt, "fast.visual_staging_contract.proof_generation", path
      assert_includes prompt, "expedition-fast-directeur-artistique-producteur", path
      assert_includes prompt, "attends son retour complet", path
      assert_match(/ne génères toi-même aucune image/, prompt, path)
      refute_includes prompt, "Le premier pixel attend l'approbation humaine", path
      assert_operator prompt.lines.length, :<, 230, path
      refute_includes prompt, "Exemples rejetés par défaut", path
      refute_includes prompt, "N'utilise ni cœur littéral", path
      refute_includes prompt, "literal_first_idea_rejected", path
      refute_includes prompt, "scene_cards", path
    end
  end

  def test_art_producer_creates_one_gated_proof_and_records_lds_aesthetic_sources
    agent_prompts("directeur-artistique-producteur").each do |path|
      prompt = File.read(path, encoding: "UTF-8")

      assert_includes prompt, "fast.result.visual_staging", path
      assert_includes prompt, "status: ready_for_proof", path
      assert_includes prompt, "authorized_by_council_contract", path
      assert_includes prompt, "BLOCKED_MISSING_VISUAL_STAGING", path
      assert_includes prompt, "staging_revision", path
      assert_includes prompt, "selection_reason", path
      assert_includes prompt, "une preuve, jamais un lot complet", path
      assert_includes prompt, "fast.visual_requirements", path
      assert_includes prompt, "proof_only", path
      assert_match(/exactement \*\*un appel de génération\*\*/, prompt, path)
      assert_match(/aucune\s+variante/, prompt, path)
      assert_includes prompt, "aucun upscale", path
      assert_includes prompt, "full_batch_authorized: false", path
      assert_includes prompt, "street_quiz_390x667", path
      assert_includes prompt, "displayed_correct_letter", path
      assert_includes prompt, "french_quiz_approval", path
      assert_match(/Ne traduis rien/, prompt, path)
      assert_includes prompt, "surface_preview_path", path
      assert_includes prompt, "critique_deux_secondes", path
      assert_includes prompt, "expedition-fast-critique-deux-secondes", path
      assert_includes prompt, "attends sa réponse complète", path
      assert_includes prompt, "image_gen", path
      assert_includes prompt, ".agents/skills/noche-art/SKILL.md", path
      assert_includes prompt, "workflow CLI", path
      assert_match(/ne bascule jamais silencieusement/, prompt, path)
      assert_includes prompt, "cinematic_realism", path
      assert_includes prompt, "biblical_illustration", path
      assert_includes prompt, "temple de Salt Lake City", path
      assert_includes prompt, "jardins splendides", path
      assert_includes prompt, "churchofjesuschrist.org", path
      assert_includes prompt, "sources publiques officielles", path
      assert_match(/N'invente ni rite, ni ordonnance/, prompt, path)
      assert_includes prompt, "public_interior", path
      assert_includes prompt, "exact_replica_claimed: false", path
      assert_includes prompt, "fast.agent_memory.direction_artistique", path
      assert_includes prompt, "fast.result.visual_production", path
      assert_match(/ne (relies|relie) rien au runtime/, prompt, path)
      assert_match(/ne publi(es|e) rien/, prompt, path)
      assert_operator prompt.lines.length, :<, 230, path
    end
  end

  def test_two_second_critic_reviews_the_real_surface_before_human_approval
    agent_prompts("critique-deux-secondes").each do |path|
      prompt = File.read(path, encoding: "UTF-8")

      assert_includes prompt, "fast.result.visual_production", path
      assert_includes prompt, "proof.output_path", path
      assert_includes prompt, "proof.surface_preview_path", path
      assert_includes prompt, "BLOCKED_MISSING_PROOF", path
      assert_includes prompt, "BLOCKED_MISSING_SURFACE_PREVIEW", path
      assert_includes prompt, ".agents/skills/noche-art/SKILL.md", path
      assert_match(/Avant de lire le concept mis en scène/, prompt, path)
      assert_includes prompt, "first_second_focus", path
      assert_includes prompt, "two_second_situation", path
      assert_includes prompt, "scroll_stop", path
      assert_includes prompt, "viewer_question", path
      assert_includes prompt, "contemplation_desire", path
      assert_includes prompt, "beauty_and_dignity", path
      assert_includes prompt, "specificity", path
      assert_includes prompt, "surface_survival", path
      assert_includes prompt, "concept_fidelity", path
      assert_includes prompt, "source_integrity", path
      assert_includes prompt, "N'accorde pas `PASS` par moyenne", path
      assert_match(/au plus\s+trois corrections/, prompt, path)
      assert_match(/ne génères ni image ni variante/, prompt, path)
      assert_match(/ne (retouches|retouche) aucun fichier/, prompt, path)
      assert_includes prompt, "fast.agent_memory.critique_deux_secondes", path
      assert_includes prompt, "fast.result.visual_proof_review", path
      assert_includes prompt, "fast.visual_proof_approval", path
      assert_includes prompt, "visual_proof_approval", path
      assert_match(/n'est ni cette décision|n'est ni\s+cette décision/, prompt, path)
      assert_operator prompt.lines.length, :<, 230, path
    end
  end

  def test_shared_art_skill_compares_conventional_and_dramaturgical_images
    prompt = File.read(NOCHE_ART, encoding: "UTF-8")

    assert_match(/A familiar symbol is not rejected\s+merely because it is familiar/, prompt)
    assert_includes prompt, "conventional, dramaturgical or hybrid"
    assert_includes prompt, "cinematic_realism"
    assert_includes prompt, "biblical_illustration"
    refute_includes prompt, "is a rejected first idea"
  end

  def test_all_agents_preserve_the_human_visual_contract_without_generating
    %w[influenceur mystique nouveau-baptise quiz voix directeur-mise-en-scene critique-deux-secondes localisateur-voix].each do |stage|
      agent_prompts(stage).each do |path|
        prompt = File.read(path, encoding: "UTF-8")

        assert_includes prompt, "fast.visual_requirements", path
        assert_match(/ne vaut|ne génère|ne produis ni image|générer des images/, prompt, path)
      end
    end
  end

  def test_pack_template_owns_nine_raw_memories_and_visual_results
    dossier = YAML.safe_load_file(TEMPLATE, aliases: false)
    expected_sequence = %w[
      expedition-fast-influenceur
      expedition-fast-mystique
      expedition-fast-nouveau-baptise
      expedition-fast-quiz
      expedition-fast-voix
      expedition-fast-directeur-mise-en-scene
      expedition-fast-directeur-artistique-producteur
      expedition-fast-critique-deux-secondes
      expedition-fast-localisateur-voix
    ]

    assert_equal 1, dossier.fetch("schema_version")
    assert_equal "expedition_fast_dossier", dossier.fetch("kind")
    assert_equal "detached", dossier.dig("lifecycle", "runtime_mode")
    assert_equal false, dossier.dig("lifecycle", "publish_authorized")
    assert_equal "full_expedition_authoring", dossier.dig("brief", "authorized_scope")
    refute dossier.key?("promotion")
    assert_equal expected_sequence, dossier.dig("council", "sequence")
    assert_equal "influenceur", dossier.dig("council", "current_stage")
    assert_equal "", dossier.dig("parent_expedition", "manifest_path")
    assert_equal [], dossier.dig("parent_expedition", "approved_source_refs")
    assert_equal "expedition-fast-directeur-artistique-producteur", dossier.dig("council", "section_owners", "fast.agent_memory.direction_artistique")
    assert_equal "expedition-fast-directeur-artistique-producteur", dossier.dig("council", "section_owners", "fast.result.visual_production")
    assert_equal "expedition-fast-critique-deux-secondes", dossier.dig("council", "section_owners", "fast.agent_memory.critique_deux_secondes")
    assert_equal "expedition-fast-critique-deux-secondes", dossier.dig("council", "section_owners", "fast.result.visual_proof_review")
    assert_equal "expedition-fast-localisateur-voix", dossier.dig("council", "section_owners", "fast.agent_memory.localisateur_voix")
    assert_equal "expedition-fast-localisateur-voix", dossier.dig("council", "section_owners", "fast.result.translations")
    assert_equal "human", dossier.dig("council", "section_owners", "fast.visual_proof_approval")
    assert_equal "human", dossier.dig("council", "section_owners", "fast.human_quiz_revision")
    assert_equal "expedition-fast-quiz", dossier.dig("council", "section_owners", "fast.result.revision_pipeline.quiz")
    assert_equal "expedition-fast-voix", dossier.dig("council", "section_owners", "fast.result.revision_pipeline.voix")
    assert_equal "expedition-fast-directeur-mise-en-scene", dossier.dig("council", "section_owners", "fast.result.revision_pipeline.mise_en_scene_visuelle")
    assert_equal "human", dossier.dig("council", "section_owners", "fast.french_quiz_approval")
    assert_equal "human", dossier.dig("council", "section_owners", "fast.translation_gate")
    assert_equal "human", dossier.dig("council", "section_owners", "fast.translation_approval")
    assert_equal MEMORY_KEYS, dossier.dig("fast", "agent_memory").keys

    MEMORY_KEYS.each do |key|
      memory = dossier.dig("fast", "agent_memory", key)

      assert memory.key?("production"), key
      assert_equal "pending", memory.fetch("status"), key
    end


    assert_equal [], dossier.dig("fast", "result", "quiz", "questions")
    assert_equal [], dossier.dig("fast", "result", "quiz_final", "questions")
    assert_equal "pending", dossier.dig("fast", "result", "visual_staging", "status")
    assert_equal false, dossier.dig("fast", "result", "visual_staging", "generation_authorized")
    assert_equal({}, dossier.dig("fast", "result", "visual_staging", "source_library"))
    assert_equal [], dossier.dig("fast", "result", "visual_staging", "visual_concepts")
    refute dossier.dig("fast", "result", "visual_staging").key?("human_approval")
    proof_contract = dossier.dig("fast", "visual_staging_contract", "proof_generation")
    assert_equal true, proof_contract.fetch("authorized_by_council_contract")
    assert_equal false, proof_contract.fetch("human_approval_before_first_proof")
    assert_equal 1, proof_contract.fetch("max_calls_before_human_review")
    assert_equal "expedition-fast-directeur-artistique-producteur", proof_contract.fetch("selection_owner")
    assert_equal true, proof_contract.fetch("human_approval_after_critic")
    assert_equal "pending", dossier.dig("fast", "result", "visual_production", "status")
    assert_equal "proof_only", dossier.dig("fast", "result", "visual_production", "production_mode")
    assert_equal false, dossier.dig("fast", "result", "visual_production", "full_batch_authorized")
    assert_equal "pending", dossier.dig("fast", "result", "visual_production", "proof", "status")
    assert_equal 0, dossier.dig("fast", "result", "visual_production", "proof", "staging_revision")
    assert_equal "", dossier.dig("fast", "result", "visual_production", "proof", "selection_reason")
    assert_equal "", dossier.dig("fast", "result", "visual_production", "proof", "surface_preview_path")
    assert_equal [], dossier.dig("fast", "result", "visual_production", "generation_records")
    assert_equal [], dossier.dig("fast", "result", "visual_production", "manifests")
    assert_equal "pending", dossier.dig("fast", "result", "visual_proof_review", "status")
    assert_equal "", dossier.dig("fast", "result", "visual_proof_review", "surface_preview_path")
    assert_equal [], dossier.dig("fast", "result", "visual_proof_review", "required_changes")
    assert_equal "human", dossier.dig("fast", "visual_proof_approval", "owner")
    assert_equal "pending", dossier.dig("fast", "visual_proof_approval", "status")
    assert_equal [], dossier.dig("fast", "visual_proof_approval", "authorized_batch", "visual_concept_ids")
    assert_equal 0, dossier.dig("fast", "human_quiz_revision", "revision")
    assert_equal "idle", dossier.dig("fast", "human_quiz_revision", "status")
    assert_equal "full", dossier.dig("fast", "human_quiz_revision", "snapshot_mode")
    assert_empty dossier.dig("fast", "human_quiz_revision", "questions")
    assert_equal 0, dossier.dig("fast", "result", "revision_pipeline", "human_revision")
    assert_equal "pending", dossier.dig("fast", "result", "revision_pipeline", "quiz", "status")
    assert_equal "pending", dossier.dig("fast", "french_quiz_approval", "status")
    assert_equal "fr", dossier.dig("fast", "french_quiz_approval", "locale")
    assert_equal 10, dossier.dig("fast", "french_quiz_approval", "required_unit_count")
    assert_equal %w[ask reveal], dossier.dig("fast", "french_quiz_approval", "required_states")
    assert_includes dossier.dig("fast", "french_quiz_approval", "required_content"), "displayed_correct_letter"
    assert_empty dossier.dig("fast", "french_quiz_approval", "review_units")
    assert_equal false, dossier.dig("fast", "translation_gate", "translation_authorized")
    assert_equal "blocked_pending_french_quiz_approval", dossier.dig("fast", "translation_gate", "status")
    assert_equal %w[es en pt-BR], dossier.dig("fast", "translation_gate", "target_locales")
    assert_equal "blocked_pending_translations", dossier.dig("fast", "translation_approval", "status")
    assert_equal %w[es en pt-BR], dossier.dig("fast", "translation_approval", "required_locales")
    assert_equal %w[es en pt-BR], dossier.dig("fast", "result", "translations", "locales").keys
    assert_equal %w[qcm vrai_faux], dossier.dig("fast", "result", "quiz", "required_formats")
    assert_equal({ "qcm" => 0, "vrai_faux" => 0 }, dossier.dig("fast", "result", "quiz", "format_mix"))
  end

  def test_expedition_template_references_autonomous_pack_files
    manifest = YAML.safe_load_file(EXPEDITION_TEMPLATE, aliases: false)

    assert_equal "expedition_fast_manifest", manifest.fetch("kind")
    assert_equal "responsable_missionnaire", manifest.dig("council", "current_stage")
    assert_equal ["expedition-fast-responsable-missionnaire"], manifest.dig("council", "sequence")
    expected_pack_sequence = %w[
      expedition-fast-influenceur
      expedition-fast-mystique
      expedition-fast-nouveau-baptise
      expedition-fast-quiz
      expedition-fast-voix
      expedition-fast-directeur-mise-en-scene
      expedition-fast-directeur-artistique-producteur
      expedition-fast-critique-deux-secondes
      expedition-fast-localisateur-voix
    ]
    assert_equal expected_pack_sequence, manifest.dig("council", "pack_sequence_template")
    assert_equal [], manifest.fetch("packs")
    assert_equal %w[
      responsable_missionnaire
      mise_en_scene_visuelle
      direction_artistique
      critique_deux_secondes
    ], manifest.dig("fast", "agent_memory").keys
    assert_equal "human", manifest.dig("fast", "source_scope_approval", "owner")
    assert_equal "pending", manifest.dig("fast", "source_scope_approval", "status")
    refute manifest.dig("fast", "result").key?("quiz")
    refute manifest.dig("fast", "result").key?("quiz_final")
    assert_equal "pending", manifest.dig("fast", "result", "visual_staging", "status")
    assert_equal "pending", manifest.dig("fast", "result", "visual_production", "status")
    assert_equal "pending", manifest.dig("fast", "result", "visual_proof_review", "status")
  end

  def test_template_carries_the_existing_mobile_copy_gate
    dossier = YAML.safe_load_file(TEMPLATE, aliases: false)
    limits = dossier.dig("fast", "quiz_copy_limits")
    original = YAML.safe_load_file(SHOWRUNNER_TEMPLATE, aliases: false).dig("formation_quizzes", "copy_limits")

    assert_equal "street_quiz_390x667", limits.fetch("reference_surface")
    assert_equal "config/expeditions/_showrunner_template.yml", limits.dig("source_contract", "document")
    assert_equal "formation_quizzes.copy_limits", limits.dig("source_contract", "path")
    assert_equal "docs/EXPEDITIONS.md#mobile-copy-gate", limits.fetch("source_documentation")
    assert_equal "unicode_graphemes_including_spaces_and_punctuation", limits.fetch("counting_unit")
    assert_equal 72, limits.dig("prompt", "hard_max")
    assert_equal 3, limits.dig("prompt", "max_lines")
    assert_equal 32, limits.dig("choice", "hard_max")
    assert_equal 2, limits.dig("choice", "max_lines")
    assert_equal 120, limits.dig("feedback", "hard_max")
    assert_equal 4, limits.fetch("max_choices")
    assert_equal({ "qcm" => 4, "vrai_faux" => 2 }, limits.fetch("choice_count_by_format"))
    assert_equal "REJECT_COPY_OVERFLOW", limits.fetch("overflow_policy")
    assert_equal %w[font_shrink truncation ellipsis answer_scroll], limits.fetch("forbidden_fixes")
    assert_equal original.fetch("counting_unit"), limits.fetch("counting_unit")
    assert_equal original.fetch("reference_surface"), limits.fetch("reference_surface")
    assert_equal original.fetch("prompt"), limits.fetch("prompt")
    assert_equal original.fetch("choice"), limits.fetch("choice")
    assert_equal original.fetch("correction"), limits.fetch("feedback")
    assert_equal original.fetch("max_choices"), limits.fetch("max_choices")
    assert_equal original.fetch("locale_policy"), limits.fetch("locale_policy")
    assert_equal original.fetch("overflow_policy"), limits.fetch("overflow_policy")
    assert_equal original.fetch("forbidden_fixes"), limits.fetch("forbidden_fixes")
  end

  def test_template_carries_the_lean_visual_staging_contract
    dossier = YAML.safe_load_file(TEMPLATE, aliases: false)
    contract = dossier.dig("fast", "visual_staging_contract")

    assert_equal false, contract.dig("source_policy", "quiz_prompt_is_source")
    assert_equal true, contract.dig("source_policy", "resolve_each_unique_reference_once")
    assert_equal true, contract.dig("source_policy", "deduplicate_in_source_library")
    assert_equal true, contract.dig("source_policy", "memory_fallback_only_when_result_is_ambiguous")
    assert_equal %w[iconic_symbol human_dramaturgy historical_cinematic environmental_world], contract.fetch("representation_modes")
    assert_equal %w[cinematic_realism biblical_illustration], contract.fetch("visual_treatments")
    assert_equal true, contract.dig("selection_policy", "conventional_images_allowed")
    assert_equal true, contract.dig("selection_policy", "dramaturgical_alternative_when_defensible")
    assert_equal %w[conventional dramaturgical hybrid], contract.dig("selection_policy", "allowed_selections")
    assert_equal true, contract.dig("selection_policy", "no_mode_has_moral_priority")
    assert_equal 160, contract.fetch("max_words_per_concept_excluding_ids_and_references")
    assert_equal false, contract.fetch("generation_authorized")
  end

  def test_template_records_the_approved_cost_optimized_visual_contract_without_authorizing_generation
    dossier = YAML.safe_load_file(TEMPLATE, aliases: false)
    visuals = dossier.dig("fast", "visual_requirements")
    surfaces = visuals.fetch("surfaces")

    assert_equal "approved_cost_optimized_contract", visuals.fetch("status")
    assert_equal false, visuals.fetch("generation_authorized")
    assert_equal "expedition-fast-directeur-artistique-producteur", visuals.fetch("production_owner")
    assert_equal 1, visuals.dig("creative_master_policy", "default_masters_per_scene")
    assert_equal false, visuals.dig("creative_master_policy", "responsive_derivatives_are_new_generations")
    assert_equal true, visuals.dig("creative_master_policy", "additional_composition_requires_documented_surface_failure")
    assert_equal true, visuals.dig("creative_master_policy", "additional_composition_requires_human_authorization")

    assert_equal "question_count", surfaces.dig("quiz_question", "expected_creative_master_count")
    assert_equal "9:16", surfaces.dig("quiz_question", "approved_master", "ratio")
    assert_equal %w[phone_quiz], surfaces.dig("quiz_question", "approved_master", "usage")
    assert_equal true, surfaces.dig("quiz_question", "tv_presenter", "uses_same_master")
    assert_equal "first_approved_quiz_master", surfaces.dig("expedition_pack_art", "source")
    assert_equal 0, surfaces.dig("expedition_pack_art", "expected_new_creative_master_count")
  end

  def test_expedition_template_records_the_shared_campaign_and_library_budget
    manifest = YAML.safe_load_file(EXPEDITION_TEMPLATE, aliases: false)
    visuals = manifest.dig("fast", "visual_requirements")
    surfaces = visuals.fetch("surfaces")

    assert_equal "approved_cost_optimized_contract", visuals.fetch("status")
    assert_equal false, visuals.fetch("generation_authorized")
    assert_equal({ "ratio" => "1:1", "width" => 2160, "height" => 2160 }, visuals.dig("creative_master_policy", "default_canvas"))
    assert_equal 7, surfaces.dig("library", "units")
    assert_equal 7, surfaces.dig("library", "maximum_new_creative_master_count")
    assert_equal %w[portrait tablet landscape], surfaces.dig("library", "derivative_targets")
    assert_equal 1, surfaces.dig("campaign_key_art", "expected_new_creative_master_count")
    assert_equal %w[expedition_key_art rama_hero home_expedition], surfaces.dig("campaign_key_art", "shared_by")
    assert_equal 0, surfaces.dig("rama_headline", "expected_image_master_count")
    assert_equal false, surfaces.dig("rama_headline", "baked_into_artwork")
    assert_equal %w[fr es en pt-BR], surfaces.dig("rama_headline", "required_locales")
    assert_equal 0, surfaces.dig("expedition_pack_art", "expected_new_creative_master_count")
    assert_equal "campaign_key_art", surfaces.dig("home_expedition", "source")
    assert_equal 0, surfaces.dig("home_expedition", "expected_new_creative_master_count")
    assert_equal 8, visuals.fetch("maximum_new_creative_master_count")
    assert_equal true, visuals.fetch("generation_count_is_a_ceiling_not_a_target")
  end

  def test_doctrine_and_covenants_run_records_human_visual_proof_approval
    dossier = YAML.safe_load_file(DOCTRINE_AND_COVENANTS_89, aliases: false)
    memories = dossier.dig("fast", "agent_memory")
    quiz = dossier.dig("fast", "result", "quiz")
    questions = quiz.fetch("questions")
    final_quiz = dossier.dig("fast", "result", "quiz_final")
    final_questions = final_quiz.fetch("questions")
    voice = dossier.dig("fast", "result", "voix")
    limits = dossier.dig("fast", "quiz_copy_limits")

    assert_equal "runtime_integrated", dossier.dig("lifecycle", "status")
    assert_equal "permanent_adventure_catalog", dossier.dig("lifecycle", "runtime_mode")
    assert_equal 66, dossier.dig("lifecycle", "current_revision")
    assert_equal "editorial_complete", dossier.dig("fast", "status")
    assert_equal "runtime_integrated", dossier.dig("council", "current_stage")
    assert_equal "full_expedition_authoring", dossier.dig("brief", "authorized_scope")
    refute dossier.key?("promotion")
    assert_equal true, dossier.dig("lifecycle", "publish_authorized")
    assert_equal "dc89_word_of_wisdom", dossier.dig("runtime_export", "pack", "id")
    assert_equal "inicios", dossier.dig("runtime_export", "pack", "insertion_after")
    assert_equal "sagesse", dossier.dig("runtime_export", "pack", "category")
    assert_equal MEMORY_KEYS, memories.keys
    assert_equal 66, dossier.dig("council", "revision_log").length
    assert_equal 66, dossier.dig("council", "revision_log").last.fetch("revision")
    assert_equal "human", dossier.dig("council", "revision_log").last.fetch("owner")
    assert_includes dossier.dig("council", "sequence"), "expedition-fast-directeur-artistique-producteur"
    assert_includes dossier.dig("council", "sequence"), "expedition-fast-critique-deux-secondes"
    assert_includes dossier.dig("council", "sequence"), "expedition-fast-localisateur-voix"

    %w[influenceur mystique nouveau_baptise].each do |key|
      assert_equal "complete", memories.dig(key, "status"), key
      refute_empty memories.dig(key, "production"), key
    end
    assert_equal 57, memories.dig("quiz", "revision")
    assert_equal "complete", memories.dig("quiz", "status")
    refute_empty memories.dig("quiz", "production")
    assert_equal 58, memories.dig("voix", "revision")
    assert_equal "complete", memories.dig("voix", "status")
    refute_empty memories.dig("voix", "production")
    assert_equal 59, memories.dig("mise_en_scene_visuelle", "revision")
    assert_equal "complete", memories.dig("mise_en_scene_visuelle", "status")
    refute_empty memories.dig("mise_en_scene_visuelle", "production")
    assert_equal 60, memories.dig("direction_artistique", "revision")
    assert_equal "complete", memories.dig("direction_artistique", "status")
    refute_empty memories.dig("direction_artistique", "production")
    assert_equal 25, memories.dig("critique_deux_secondes", "revision")
    assert_equal "complete", memories.dig("critique_deux_secondes", "status")
    refute_empty memories.dig("critique_deux_secondes", "production")
    assert_equal 65, memories.dig("localisateur_voix", "revision")
    assert_equal "complete", memories.dig("localisateur_voix", "status")
    refute_empty memories.dig("localisateur_voix", "production")

    assert_equal 10, questions.length
    actual_mix = questions.group_by { |question| question.fetch("type") }.transform_values(&:length)
    actual_format_mix = questions.group_by { |question| question.fetch("format") }.transform_values(&:length)

    assert_equal({ "texte" => 6, "vie" => 4 }, actual_mix)
    assert_equal({ "texte" => 6, "vie" => 4 }, quiz.fetch("question_mix"))
    assert_equal "complete", quiz.fetch("status")
    assert_equal %w[qcm vrai_faux], quiz.fetch("required_formats")
    assert_equal({ "qcm" => 6, "vrai_faux" => 4 }, actual_format_mix)
    assert_equal({ "qcm" => 6, "vrai_faux" => 4, "undeclared" => 0 }, quiz.fetch("format_mix"))

    assert_equal 7, quiz.fetch("source_human_revision")
    assert_equal 7, voice.fetch("source_human_revision")
    assert_equal 57, voice.fetch("source_quiz_revision")
    assert_equal 58, voice.fetch("copy_revision")
    assert_equal "complete", voice.fetch("status")
    assert_equal true, voice.fetch("read_aloud_performed")
    assert_equal "complete_sequence_prompt_choices_feedback", voice.fetch("read_aloud_scope")
    assert_equal "verified", voice.dig("ui_surfaces", "street_quiz_390x667")
    assert_equal({ "width" => 390, "height" => 667 }, voice.dig("render_evidence", "viewport"))
    assert_equal({ "qcm" => 4, "vrai_faux" => 2 }, voice.dig("render_evidence", "choice_formats_verified"))
    assert_equal 10, voice.dig("render_evidence", "asks_inspected")
    assert_equal 10, voice.dig("render_evidence", "feedbacks_inspected")
    assert_equal 20, voice.dig("render_evidence", "screenshots_reviewed")
    assert_equal 10, voice.dig("render_evidence", "wrong_answers_submitted")
    assert_equal 1, voice.dig("render_evidence", "marked_correct_rows_per_question")
    assert_equal true, voice.dig("render_evidence", "exact_feedback_verified")
    assert_equal true, voice.dig("render_evidence", "shuffled_positions_verified")
    assert_equal "A", voice.dig("render_evidence", "displayed_correct_letters", "fast-dc89-q05")
    assert_equal "B", voice.dig("render_evidence", "displayed_correct_letters", "fast-dc89-q09")
    assert_equal "B", voice.dig("render_evidence", "displayed_correct_letters", "fast-dc89-q10")
    assert_equal({ "source_choice_id" => "b", "source_text" => "Faux", "displayed_letter" => "B" }, voice.dig("render_evidence", "q09_correct_choice_proof"))
    assert_equal({ "source_choice_id" => "c", "source_text" => "Par révélation", "displayed_letter" => "B" }, voice.dig("render_evidence", "q10_correct_choice_proof"))
    assert_equal "none", voice.dig("render_evidence", "clipping")
    assert_equal "none", voice.dig("render_evidence", "truncation")
    assert_equal 0, voice.dig("render_evidence", "browser_console_severe_entries")
    assert_equal "pass", voice.dig("checks", "game_show_voice")
    assert_equal "pass", voice.dig("checks", "mobile_copy_gate")
    assert_equal "pass", voice.dig("checks", "meaning_preserved")
    assert_equal 10, voice.fetch("question_audits").length

    assert_equal 10, final_questions.length
    assert_equal({ "texte" => 6, "vie" => 4 }, final_quiz.fetch("question_mix"))
    assert_equal %w[qcm vrai_faux], final_quiz.fetch("required_formats")
    assert_equal({ "qcm" => 6, "vrai_faux" => 4 }, final_quiz.fetch("format_mix"))
    assert_equal "ready_for_batch_authorization", dossier.dig("fast", "result", "visual_staging", "status")
    assert_equal false, dossier.dig("fast", "result", "visual_staging", "generation_authorized")
    assert_equal 10, dossier.dig("fast", "result", "visual_staging", "source_library").length
    assert_equal 10, dossier.dig("fast", "result", "visual_staging", "visual_concepts").length
    assert dossier.dig("fast", "result", "visual_staging", "visual_concepts").all? { |concept| concept.fetch("surfaces") == ["quiz_question"] }
    assert_equal "batch_generated_awaiting_human_review", dossier.dig("fast", "result", "visual_production", "status")
    assert_equal "authorized_quiz_batch", dossier.dig("fast", "result", "visual_production", "production_mode")
    assert_equal true, dossier.dig("fast", "result", "visual_production", "full_batch_authorized")
    assert_equal "dc89-visual-q02", dossier.dig("fast", "result", "visual_production", "proof", "visual_concept_id")
    assert_equal "9:16", dossier.dig("fast", "result", "visual_production", "proof", "ratio")
    assert_equal 11, dossier.dig("fast", "result", "visual_production", "generation_records").length
    assert_equal 11, dossier.dig("fast", "result", "visual_production", "manifests").length
    assert_equal 9, dossier.dig("fast", "result", "visual_production", "batch", "new_generation_call_count")
    assert_equal 0, dossier.dig("fast", "result", "visual_production", "batch", "variant_count")
    assert_equal 20, dossier.dig("fast", "result", "visual_production", "batch", "preview_count")
    assert_equal "1 run, 1135 assertions, 0 failures, 0 errors", dossier.dig("fast", "result", "visual_production", "batch", "real_surface_test")
    assert_equal "awaiting_human_proof_approval", dossier.dig("fast", "result", "visual_proof_review", "status")
    assert_equal "REWORK", dossier.dig("fast", "result", "visual_proof_review", "verdict")
    assert_equal 2, dossier.dig("fast", "result", "visual_proof_review", "required_changes").length
    assert_equal "approved", dossier.dig("fast", "visual_proof_approval", "status")
    assert_equal "approve_proof", dossier.dig("fast", "visual_proof_approval", "decision")
    assert_equal true, dossier.dig("fast", "visual_proof_approval", "requested_copy_change")
    assert_equal 10, dossier.dig("fast", "visual_proof_approval", "authorized_batch", "visual_concept_ids").length
    assert_equal ["9:16"], dossier.dig("fast", "visual_proof_approval", "authorized_batch", "ratios")
    assert_equal ["dc89-visual-q02"], dossier.dig("fast", "visual_proof_approval", "authorized_batch", "reuse_existing_visual_concept_ids")
    assert_equal "approved", dossier.dig("fast", "french_quiz_approval", "status")
    assert_equal "approved", dossier.dig("fast", "french_quiz_approval", "text_approval_status")
    assert_equal 61, dossier.dig("fast", "french_quiz_approval", "text_approval_revision")
    review_units = dossier.dig("fast", "french_quiz_approval", "review_units")
    assert_equal 10, review_units.length
    assert review_units.all? { |unit| unit.fetch("status") == "approved" }
    assert review_units.all? { |unit| File.exist?(File.join(ROOT, unit.fetch("image_path"))) }
    assert review_units.all? { |unit| unit.fetch("ask_preview_path").start_with?("tmp/") }
    assert review_units.all? { |unit| unit.dig("preview_sha256", "ask").match?(/\A[0-9a-f]{64}\z/) }
    assert review_units.all? { |unit| unit.fetch("reveal_preview_path").start_with?("tmp/") }
    assert review_units.all? { |unit| unit.dig("preview_sha256", "reveal").match?(/\A[0-9a-f]{64}\z/) }
    assert_equal true, dossier.dig("fast", "translation_gate", "translation_authorized")
    assert_equal 61, dossier.dig("fast", "translation_gate", "source_approval_revision")
    translations = dossier.dig("fast", "result", "translations")
    assert_equal "complete_awaiting_human_validation", translations.fetch("status")
    assert_equal 61, translations.fetch("source_approval_revision")
    assert_equal 65, translations.fetch("production_revision")
    assert_equal 3213, translations.dig("system_test", "assertions")
    assert_equal 0, translations.dig("system_test", "failures")
    assert_equal 0, translations.dig("system_test", "errors")
    assert_equal %w[es en pt-BR], translations.fetch("locales").keys
    translations.fetch("locales").each do |locale, localized|
      assert_equal "complete", localized.fetch("status"), locale
      assert_equal "PASS", localized.fetch("voice_gate"), locale
      assert_equal "PASS", localized.fetch("mobile_copy_gate"), locale
      assert_equal 10, localized.fetch("questions").length, locale
      assert_equal 10, localized.fetch("question_audits").length, locale
      final_questions.zip(localized.fetch("questions")).each do |source_question, localized_question|
        %w[id type format reference correct_choice].each do |field|
          assert_equal source_question.fetch(field), localized_question.fetch(field), "#{locale} #{source_question.fetch('id')} #{field}"
        end
        assert_equal source_question.fetch("choices").map { |choice| choice.fetch("id") }, localized_question.fetch("choices").map { |choice| choice.fetch("id") }
        assert_operator grapheme_count(localized_question.fetch("prompt")), :<=, limits.dig("prompt", "hard_max"), "#{locale} #{source_question.fetch('id')} prompt"
        localized_question.fetch("choices").each do |choice|
          assert_operator grapheme_count(choice.fetch("text")), :<=, limits.dig("choice", "hard_max"), "#{locale} #{source_question.fetch('id')} choice"
        end
        assert_operator grapheme_count(localized_question.fetch("feedback")), :<=, limits.dig("feedback", "hard_max"), "#{locale} #{source_question.fetch('id')} feedback"
      end
    end
    translation_approval = dossier.dig("fast", "translation_approval")
    assert_equal "approved", translation_approval.fetch("status")
    assert_equal 65, translation_approval.fetch("translation_revision")
    assert_equal %w[es en pt-BR], translation_approval.fetch("required_locales")
    translation_approval.fetch("locales").each do |locale, approval|
      assert_equal "approved", approval.fetch("status"), locale
      assert_equal 10, approval.fetch("review_units").length, locale
      assert approval.fetch("review_units").all? { |unit| unit.fetch("ask_preview_path").start_with?("tmp/") }, locale
      assert approval.fetch("review_units").all? { |unit| unit.dig("preview_sha256", "ask").match?(/\A[0-9a-f]{64}\z/) }, locale
      assert approval.fetch("review_units").all? { |unit| unit.fetch("reveal_preview_path").start_with?("tmp/") }, locale
      assert approval.fetch("review_units").all? { |unit| unit.dig("preview_sha256", "reveal").match?(/\A[0-9a-f]{64}\z/) }, locale
    end

    human_revision = dossier.dig("fast", "human_quiz_revision")
    revision_pipeline = dossier.dig("fast", "result", "revision_pipeline")
    assert_equal 7, human_revision.fetch("revision")
    assert_equal "submitted", human_revision.fetch("status")
    assert_equal "full", human_revision.fetch("snapshot_mode")
    assert_equal 10, human_revision.fetch("questions").length
    assert_equal human_revision.fetch("questions"), questions
    assert_equal ["fast-dc89-q05"], human_revision.fetch("changed_question_ids")
    assert_equal ["fast-dc89-q05"], human_revision.fetch("reference_changed_question_ids")
    assert_equal ["dc89-visual-q05"], human_revision.dig("invalidation", "visual_concept_ids")
    assert_equal 7, revision_pipeline.fetch("human_revision")
    assert_equal "processed", revision_pipeline.fetch("status")
    %w[quiz voix mise_en_scene_visuelle].each do |agent|
      assert_equal 7, revision_pipeline.dig(agent, "processed_revision"), agent
      assert_equal "complete", revision_pipeline.dig(agent, "status"), agent
    end

    q09 = final_questions.find { |question| question.fetch("id") == "fast-dc89-q09" }
    assert_equal "D&A 89:8", q09.fetch("reference")
    assert_equal "Vrai ou faux : D&A 89 permet de fumer ou de chiquer du tabac.", q09.fetch("prompt")
    assert_equal "b", q09.fetch("correct_choice")
    assert_includes q09.fetch("feedback"), "fumer ou le chiquer est proscrit"

    q05 = final_questions.find { |question| question.fetch("id") == "fast-dc89-q05" }
    assert_equal "D&A 89:12-13", q05.fetch("reference")
    assert_equal "Quand est-il agréable au Seigneur de consommer de la viande ?", q05.fetch("prompt")
    assert_equal "a", q05.fetch("correct_choice")
    assert_equal "En hiver, au froid ou en famine", q05.fetch("choices").find { |choice| choice.fetch("id") == "a" }.fetch("text")
    assert_includes q05.fetch("feedback"), "avec économie"

    q10 = final_questions.find { |question| question.fetch("id") == "fast-dc89-q10" }
    assert_equal "texte", q10.fetch("type")
    assert_equal "D&A 89:2", q10.fetch("reference")
    assert_equal "Selon le verset 2, comment la Parole de Sagesse est-elle envoyée ?", q10.fetch("prompt")
    assert_equal "c", q10.fetch("correct_choice")
    assert_equal "Par révélation", q10.fetch("choices").find { |choice| choice.fetch("id") == "c" }.fetch("text")
    assert_includes q10.fetch("feedback"), "ni par commandement ni par contrainte, mais par révélation"
    refute_includes q10.to_s, "sacrifice de cœur"

    questions.zip(final_questions).each do |draft, final|
      expected_choice_count = limits.dig("choice_count_by_format", draft.fetch("format"))
      draft_choices = draft.fetch("choices")
      final_choices = final.fetch("choices")

      %w[id type format reference correct_choice].each do |field|
        assert_equal draft.fetch(field), final.fetch(field), "#{draft.fetch("id")}: #{field}"
      end
      assert_equal expected_choice_count, draft_choices.length, draft.fetch("id")
      assert_equal expected_choice_count, final_choices.length, final.fetch("id")
      assert_equal draft_choices.map { |choice| choice.fetch("id") }, final_choices.map { |choice| choice.fetch("id") }
      assert_includes final_choices.map { |choice| choice.fetch("id") }, final.fetch("correct_choice")
      assert_operator grapheme_count(final.fetch("prompt")), :<=, limits.dig("prompt", "hard_max"), final.fetch("id")
      final_choices.each do |choice|
        assert_operator grapheme_count(choice.fetch("text")), :<=, limits.dig("choice", "hard_max"), final.fetch("id")
      end
      assert_operator grapheme_count(final.fetch("feedback")), :<=, limits.dig("feedback", "hard_max"), final.fetch("id")
    end

    serialized = File.read(DOCTRINE_AND_COVENANTS_89, encoding: "UTF-8")
    refute_includes serialized, "Aucun critère de difficulté"

    visuals = dossier.dig("fast", "visual_requirements")

    assert_equal false, visuals.fetch("generation_authorized")
    assert_equal "expedition-fast-directeur-artistique-producteur", visuals.fetch("production_owner")
    assert_equal 20, visuals.dig("surfaces", "quiz_question", "expected_master_count")
    assert_equal 21, visuals.dig("surfaces", "library", "expected_master_count")
    assert_equal 3, visuals.dig("surfaces", "rama_hero", "expected_master_count")
    assert_equal 3, visuals.dig("surfaces", "expedition_key_art", "expected_master_count")
    assert_equal 47, visuals.dig("counts", "required_excluding_pack_art")
    assert_equal 49, visuals.dig("counts", "required_plus_optional_home")
  end

  private

    def agent_prompts(stage)
      [
        File.join(ROOT, ".codex/agents/expedition-fast-#{stage}.toml"),
        File.join(ROOT, ".cursor/agents/expedition-fast-#{stage}.md")
      ]
    end

    def grapheme_count(value)
      value.scan(/\X/).length
    end
end
