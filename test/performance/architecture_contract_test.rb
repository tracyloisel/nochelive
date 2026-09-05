require "test_helper"
require "erb"
require "yaml"
require "digest"
require "zlib"

class ArchitectureContractTest < ActiveSupport::TestCase
  test "Noche Live has no parallel quiz engine" do
    obsolete_paths = %w[
      app/assets/stylesheets/surfaces/missions.css
      app/controllers/ward_mission_advances_controller.rb
      app/controllers/ward_mission_answers_controller.rb
      app/controllers/ward_mission_plays_controller.rb
      app/controllers/ward_mission_stage_starts_controller.rb
      app/controllers/ward_missions_controller.rb
      app/models/ward_mission.rb
      app/models/ward_mission_answer.rb
      app/models/ward_mission_entry.rb
      app/models/ward_mission_run.rb
      app/models/ward_mission_stage.rb
      app/services/ward_missions.rb
    ]
    obsolete_paths.each do |path|
      refute Rails.root.join(path).exist?, "obsolete WardMission engine file remains: #{path}"
    end

    %w[
      ward_mission_answers
      ward_mission_runs
      ward_mission_entries
      ward_mission_stages
      ward_missions
    ].each do |table|
      refute ActiveRecord::Base.connection.data_source_exists?(table), "obsolete WardMission table remains: #{table}"
    end

    sequence = Rails.root.join("app/services/nights/quiz_sequence.rb").read
    assert_includes sequence, "QuizRun.create!"
    assert_includes sequence, "live_sequence_position"
    assert_includes Rails.root.join("app/controllers/play_controller.rb").read, "Quizzes::Draw.frame"
    assert_includes Rails.root.join("app/services/quizzes/advance.rb").read, "Nights::QuizSequence.next_after"
  end

  test "feature controllers use the shared request and frame ownership contracts" do
    controller_sources = Rails.root.glob("app/javascript/controllers/*_controller.js").to_h { |path| [ path, path.read ] }

    controller_sources.each do |path, source|
      refute_match(/(?<![\w.])fetch\s*\(/, source, "raw fetch in #{path.relative_path_from(Rails.root)}")
      refute_includes source, "requestAnimationFrame", "unowned RAF in #{path.relative_path_from(Rails.root)}"
      refute_includes source, "new Image", "raw image prefetch in #{path.relative_path_from(Rails.root)}"
    end
  end

  test "controllers do not overwrite Stimulus reserved scope getter" do
    Rails.root.glob("app/javascript/controllers/*_controller.js").each do |path|
      refute_match(/this\.scope\s*=/, path.read, "reserved Stimulus scope overwritten in #{path.relative_path_from(Rails.root)}")
    end
  end

  test "Motion and Howler imports stay behind their platform backends" do
    javascript = Rails.root.glob("app/javascript/**/*.js")
    motion_importers = javascript.select { |path| path.read.match?(/from ["']motion["']/) }
    howler_importers = javascript.select { |path| path.read.match?(/(?:import|from) ["']howler-core["']/) }

    assert_equal [ Rails.root.join("app/javascript/platform/motion/motion_backend.js") ], motion_importers
    assert_equal [ Rails.root.join("app/javascript/platform/audio/howler_backend.js") ], howler_importers
    refute_includes Rails.root.join("app/javascript/application.js").read, "motion"
    refute_includes Rails.root.join("app/javascript/application.js").read, "howler"
  end

  test "audio consumers use the module port without application globals" do
    Rails.root.glob("app/javascript/**/*.js").each do |path|
      refute_match(/window\.NocheLiveAudio|window\.NocheSfx|NocheAudio(?:Loader|Bootstrap|Native)Store/, path.read,
        "audio global in #{path.relative_path_from(Rails.root)}")
    end

    layout = Rails.root.join("app/views/layouts/application.html.erb").read
    assert_includes layout, 'id="noche_sfx_catalog"'
    refute_includes layout, "window.NocheSfx"
  end

  test "first-screen counters do not pull the Motion library into the Hub" do
    runtime = Rails.root.join("app/javascript/runtime/motion/runtime.js").read
    library_runtime = Rails.root.join("app/javascript/runtime/motion/library_runtime.js").read
    duel = Rails.root.join("app/javascript/controllers/duel_motion_controller.js").read

    assert_includes runtime, "platform/motion/native_backend"
    refute_includes runtime, "platform/motion/motion_backend"
    assert_includes library_runtime, "platform/motion/motion_backend"
    assert_includes duel, "runtime/motion/library_runtime"
  end

  test "audible pages load the native mixer only after a user gesture" do
    stage = Rails.root.join("app/javascript/controllers/stage_controller.js").read
    loader = Rails.root.join("app/javascript/platform/audio/loader.js").read
    javascript = Rails.root.glob("app/javascript/**/*.js")
    native_importers = javascript.select { |path| path.read.match?(/from ["']platform\/audio\/native_backend["']/) }

    assert_includes stage, 'from "platform/audio/loader"'
    assert_empty native_importers
    assert_includes loader, 'import("platform/audio/native_backend")'
    assert_match(/function onGesture[\s\S]*syncUnlock\(\)[\s\S]*loadBackend\(\)/, loader)
  end

  test "global body controllers are small allowlisted adapters" do
    layout = Rails.root.join("app/views/layouts/application.html.erb").read
    assert_includes layout, 'data-controller="loading press motion hud-scroll scripture-launcher pwa-install'
    refute_match(/data-controller="[^"]*(?:^|\s)scripture(?:\s|\")/, layout)

    adapters = %w[loading press motion hud_scroll scripture_launcher pwa_install stage].map do |name|
      path = Rails.root.join("app/javascript/controllers/#{name}_controller.js")
      assert_operator path.readlines.size, :<=, 200, "global adapter is too large: #{path.relative_path_from(Rails.root)}"
      path
    end
    compressed = adapters.sum { |path| Zlib.gzip(path.read).bytesize }
    assert_operator compressed, :<=, 8.kilobytes, "global Stimulus adapters exceed their transition budget"
  end

  test "contextual reader waits for its stylesheet before mounting the Turbo Frame" do
    launcher = Rails.root.join("app/javascript/controllers/scripture_launcher_controller.js").read

    assert_match(/async prepare\(event\)[\s\S]*event\.preventDefault\(\)[\s\S]*await this\.ensureStylesheet\(\)[\s\S]*frameTarget\.setAttribute\("src", this\.pendingUrl\)/, launcher)
    assert_match(/async retry\(event\)[\s\S]*await this\.ensureStylesheet\(\)/, launcher)
  end

  test "CSS is partitioned into a small shell and bounded route surfaces" do
    root = Rails.root.join("app/assets/stylesheets")
    shell = root.join("application.css")
    loading = root.join("shell/loading.css")
    surfaces = Rails.root.glob("app/assets/stylesheets/surfaces/*.css").index_by(&:basename)

    assert_operator Zlib.gzip(shell.read).bytesize, :<=, 25.kilobytes
    assert_operator surfaces.size, :>=, 10
    surfaces.each do |name, path|
      assert_operator Zlib.gzip(path.read).bytesize, :<=, 50.kilobytes, "surface CSS exceeds 50 KiB: #{name}"
    end
    refute_match(/#street_quiz|\.hub-(?!menu-)|body\.is-play|body\.is-watch|\.study-|\.scripture-/, shell.read)

    route_budgets = {
      hub: [ shell, loading, surfaces.fetch(Pathname("hub.css")) ],
      live: [ shell, loading, surfaces.fetch(Pathname("gameplay.css")), surfaces.fetch(Pathname("live.css")) ],
      street_play: [ shell, loading, surfaces.fetch(Pathname("gameplay.css")), surfaces.fetch(Pathname("street_play.css")), root.join("duel_campus.css") ],
      stats: [ shell, loading, surfaces.fetch(Pathname("stats.css")) ],
      study_reader: [ shell, loading, surfaces.fetch(Pathname("study.css")), surfaces.fetch(Pathname("scripture.css")) ],
      church: [ shell, loading, surfaces.fetch(Pathname("church.css")) ],
      profile: [ shell, loading, surfaces.fetch(Pathname("entry.css")), surfaces.fetch(Pathname("profile.css")) ],
      rama: [ shell, loading, surfaces.fetch(Pathname("profile.css")), surfaces.fetch(Pathname("rama.css")) ]
    }
    route_budgets.each do |route, paths|
      compressed = paths.sum { |path| Zlib.gzip(path.read).bytesize }
      assert_operator compressed, :<=, 64.kilobytes, "#{route} CSS exceeds 64 KiB"
    end

    ApplicationHelper::FRONTEND_CONTROLLER_STYLES.each do |controller, names|
      paths = [ shell, loading, *names.map { |name| surfaces.fetch(Pathname("#{name}.css")) } ]
      compressed = paths.sum { |path| Zlib.gzip(path.read).bytesize }
      assert_operator compressed, :<=, 64.kilobytes, "#{controller} fallback CSS exceeds 64 KiB"
    end
  end

  test "loader shell is autonomous and below its compressed budget" do
    css = Rails.root.join("app/assets/stylesheets/shell/loading.css")
    source = css.read
    compressed = Zlib.gzip(source).bytesize

    assert_operator compressed, :<=, 6.kilobytes
    refute_match(/url\(|@import|font-family/, source)
    loader = Rails.root.join("app/javascript/controllers/loading_controller.js").read
    refute_match(/motion|howler|audio\/|media\//i, loader)
  end

  test "responsive media manifest has real width variants and immutable files" do
    manifest = JSON.parse(Rails.root.join("config/media/generated_manifest.json").read)
    assert_equal "media/masters", manifest.fetch("source_root")
    assert_operator manifest.fetch("assets").size, :>=, 400
    expected_paths = []

    manifest.fetch("assets").each do |key, asset|
      assert_includes %w[hub_backdrop hub_hero library_daily_hero rama_weekly_hero hub_card catalog_portrait catalog_landscape catalog_square catalog_icon], asset.fetch("role"), key
      assert asset.fetch("source_width").positive?, key
      assert asset.fetch("source_bytes").positive?, key
      assert asset.fetch("ratio").present?, key
      assert asset.fetch("focus").present?, key
      assert asset.fetch("theme").present?, key
      assert Rails.root.join("media/masters", asset.fetch("source")).file?, key
      public_source = Rails.root.join("public", asset.fetch("source"))
      if public_source.file?
        refute_equal asset.fetch("source_sha256"), Digest::SHA256.file(public_source).hexdigest,
          "master leaked into public: #{key}"
      end

      asset.fetch("renditions").each do |rendition_name, rendition|
        rendition_master = Rails.root.join("media/masters", rendition.fetch("source"))
        assert rendition_master.file?, "#{key} #{rendition_name} master"
        assert_equal rendition.fetch("source_sha256"), Digest::SHA256.file(rendition_master).hexdigest
        assert_equal rendition.fetch("source_bytes"), rendition_master.size
        assert rendition.fetch("source_width").positive?, "#{key} #{rendition_name} width"
        assert rendition.fetch("source_height").positive?, "#{key} #{rendition_name} height"
        assert rendition.fetch("ratio").present?, "#{key} #{rendition_name}"
        %w[avif webp jpeg].each do |format|
          variants = rendition.dig("variants", format)
          assert_operator variants.size, :>=, 1, "#{key} #{rendition_name} #{format}"
          assert_equal variants.map { |row| row.fetch("width") }.sort.uniq, variants.map { |row| row.fetch("width") }
          variants.each do |variant|
            path = Rails.root.join("public", variant.fetch("src").delete_prefix("/"))
            expected_paths << path
            assert path.file?, path
            assert_equal variant.fetch("bytes"), path.size
            assert_equal variant.fetch("sha256"), Digest::SHA256.file(path).hexdigest
          end
        end
      end
      mobile = asset.dig("variants", "avif").min_by { |row| row.fetch("width") }
      assert_operator mobile.fetch("bytes"), :<=, 160.kilobytes, key
    end


    generated_paths = Rails.root.glob("public/media/generated/**/*").select(&:file?).sort
    assert_equal expected_paths.sort, generated_paths

    hub = manifest.dig("assets", "hub.backdrop.moises-mer-rouge", "renditions")
    assert_equal "9:16", hub.dig("portrait", "ratio")
    assert_equal "(max-width: 767px)", hub.dig("portrait", "media")
    assert_equal "16:9", hub.dig("landscape", "ratio")
    assert_equal "(min-width: 768px)", hub.dig("landscape", "media")
    assert_equal "media/home/moises-mer-rouge-landscape-v2.png", hub.dig("landscape", "source")
    assert_equal 1672, hub.dig("landscape", "source_width")
    assert_equal [ 768, 1440, 1672 ], hub.dig("landscape", "variants", "avif").pluck("width")
  end

  test "vendored runtime dependencies match reviewed hashes" do
    expected = {
      "vendor/javascript/howler-core-2.2.4.js" => "e7b836445d8c44bddc99b7678fa336a9d5c5ede27cc709c5fae8b1748ba7431b",
      "vendor/javascript/motion-13.1.1.js" => "bab41f3579239576784977cb218b6f8a243b1f3df46438e4bfb43ae2a657ca3a"
    }
    expected.each do |relative, digest|
      assert_equal digest, Digest::SHA256.file(Rails.root.join(relative)).hexdigest
    end
  end

  test "production realtime uses Redis instead of database polling" do
    source = Rails.root.join("config/cable.yml").read
    cable = YAML.safe_load(ERB.new(source).result)
    production = cable.fetch("production")

    assert_equal "redis", production.fetch("adapter")
    assert_includes source, 'ENV["REDIS_URL"]'
    refute production.key?("polling_interval")
  end

  test "browser presence heartbeats stay on the websocket" do
    source = Rails.root.join("app/javascript/controllers/presence_controller.js").read

    assert_includes source, "cable.subscribeTo"
    assert_includes source, 'perform("heartbeat")'
    refute_match(/\bfetch\s*\(/, source)
    refute_match(/XMLHttpRequest/, source)
  end

  test "render provisions one shared realtime store for web and worker" do
    blueprint = YAML.safe_load(Rails.root.join("render.yaml").read)
    services = blueprint.fetch("services")
    realtime = services.find { |service| service["type"] == "keyvalue" }

    assert_equal "nochelive-realtime", realtime.fetch("name")
    assert_equal "allkeys-lru", realtime.fetch("maxmemoryPolicy")

    %w[web worker].each do |type|
      service = services.find { |candidate| candidate["type"] == type }
      variables = service.fetch("envVars").index_by { |variable| variable.fetch("key") }
      redis = variables.fetch("REDIS_URL").fetch("fromService")

      assert_equal "nochelive-realtime", redis.fetch("name")
      assert_equal "keyvalue", redis.fetch("type")
    end
  end

  test "production keeps cache and immutable asset delivery off PostgreSQL and Puma" do
    production = Rails.root.join("config/environments/production.rb").read
    blueprint = Rails.root.join("render.yaml").read

    assert_includes production, "config.cache_store = :redis_cache_store"
    assert_includes production, "immutable"
    assert_includes blueprint, "https://nochelive-assets-prod.storage.googleapis.com"
    refute_includes blueprint, "RAILS_SERVE_STATIC_FILES"
  end

  test "a production push synchronizes assets before Render can deploy" do
    hook = Rails.root.join(".githooks/pre-push").read

    assert_includes hook, 'GCS_SYNC_PUSH_BRANCH:-main'
    assert_includes hook, 'exec bin/sync_gcs_assets'
    assert_includes hook, 'GCS_ASSET_SYNC_SKIP'
  end

  test "asset host middleware never buffers the complete response" do
    source = Rails.root.join("lib/public_asset_host.rb").read

    assert_includes source, "RewritingBody.new(body, host)"
    refute_match(/body\.each\s*\{[^}]*source\s*<</m, source)
    refute_match(/rewritten\.bytesize/, source)
  end

  test "the Campus replaces the legacy mono-duel engine instead of wrapping it" do
    legacy_paths = %w[
      app/javascript/controllers/duel_board_controller.js
      app/javascript/controllers/hub_challenge_controller.js
      app/services/hubs/invitations.rb
      app/services/quizzes/challenge_accept.rb
      app/services/quizzes/challenge_board.rb
      app/services/quizzes/challenge_create.rb
      app/services/quizzes/challenge_decline.rb
      app/services/quizzes/challenge_inbox.rb
      app/services/quizzes/challenge_notify.rb
      app/services/quizzes/challenge_resolve.rb
      app/services/quizzes/challenge_rivals.rb
      app/services/quizzes/challenge_screen.rb
      app/services/quizzes/ensure_hub_duel.rb
      app/services/quizzes/rival.rb
      app/services/quizzes/stake_rivalry.rb
    ]
    legacy_paths.each { |path| refute Rails.root.join(path).exist?, "legacy challenge file still exists: #{path}" }

    css = Rails.root.glob("app/assets/stylesheets/**/*.css").map(&:read).join("\n")
    refute_match(/street-duel|street-stake|hub-challenge|hub-invitations|street-ceremony-(?:afterplay|secondary-actions|waiting|laurel)|body\.is-duel-show/, css)

    %w[es fr en pt-BR].each do |locale|
      source = Rails.root.join("config/locales/#{locale}.yml").read
      refute_match(/^    (?:duel_|stake_|card_rival)/, source)
    end

    assert DuelInvitation.table_exists?
    refute_includes QuizRun.column_names, "street_duel_id"
    refute_includes StreetDuel.column_names, "pack_id"
    refute_includes StreetDuel.column_names, "token"
    refute_includes StreetDuel.column_names, "challenger_delta"
    refute_includes StreetDuel.column_names, "opponent_delta"
    refute_includes StreetDuel.column_names, "ward_id"
    refute_includes StreetDuel.column_names, "stake_unit_id"
    assert_nil QuizRun.reflect_on_association(:street_duel)

    {
      "duel_invitations" => %w[challenger_run_id],
      "street_duels" => %w[challenger_run_id opponent_run_id]
    }.each do |table, columns|
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(table)
      columns.each do |column|
        foreign_key = foreign_keys.find { |candidate| candidate.column == column }
        assert_equal :nullify, foreign_key&.on_delete, "#{table}.#{column} must nullify deleted runs"
      end
    end
  end
end
