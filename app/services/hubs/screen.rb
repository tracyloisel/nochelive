module Hubs
  class Screen
    Player = Struct.new(
      :name, :rank_key, :level, :xp_now, :xp_next, :xp_progress,
      :crowns, :streak, :avatar_key, :guest, keyword_init: true
    )
    Hero = Struct.new(
      :kicker, :title, :lede, :step_n, :step_total, :reward, :still,
      :method, :path, keyword_init: true
    )
    Slide = Struct.new(
      :kind, :title, :kicker, :lede, :still, :state,
      :step_n, :step_total, :reward, :method, :path,
      keyword_init: true
    )
    Voyage = Struct.new(:previous, :current, :next, keyword_init: true)
    Live = Struct.new(
      :state, :starts_at, :title, :join_path, :program_path, :still,
      :theme_mode, :theme_atmosphere, :ward_pick_path,
      keyword_init: true
    )
    CHAPEL_STILL = "media/church/worship.jpg"
    LIVE_WINDOW = 14.days
    Gain = Struct.new(:name, :points, :at, :avatar_key, keyword_init: true)
    League = Struct.new(:rank, :players, :rival_name, :rival_gap, :recent_gains, keyword_init: true)
    # The Home uses the active week only to offer its real programme and one
    # of its concrete chapters. Historical run/player aggregate data belonged
    # to the retired dashboard, not this editorial surface.
    Study = Struct.new(:week, :weekly_reading_cards, keyword_init: true)
    Result = Struct.new(
      :player, :hero, :voyage, :live, :rama_events, :circle, :study, :reading_cards, :backdrop, :league,
      keyword_init: true
    )

    def self.call(device_digest:, person: nil, ward: nil, at: Time.current, open_run: nil, world: nil)
      new(device_digest:, person:, ward:, at:, open_run:, world:).call
    end

    def initialize(device_digest:, person: nil, ward: nil, at: Time.current, open_run: nil, world: nil)
      @digest = device_digest.to_s
      @person = person
      @ward = ward
      @at = at
      @open_run = open_run
      @world = world || Quizzes::World.call(device_digest: @digest, person_id: @person&.id)
      @helpers = Rails.application.routes.url_helpers
    end

    def call
      live = build_live
      reading_suggestions = Quizzes::ReadingSuggestions.call(person: @person)
      Result.new(
        player: build_player,
        hero: build_hero,
        voyage: build_voyage,
        live:,
        # Live is a full-width moment immediately after the hero. The local
        # block intentionally receives only verified ward events so the same
        # Noche Live can never be rendered twice on the Hub.
        rama_events: Hubs::RamaEvents.call(ward: @ward, at: @at),
        circle: Hubs::CircleDiscovery.call(person: @person, ward: @ward, theme: backdrop.theme.mode),
        study: build_study,
        reading_cards: Hubs::ReadingCards.call(person: @person, suggestions: reading_suggestions),
        backdrop:,
        league: build_league
      )
    end

    private

      def total_score
        return 0 unless @ward && @person

        @total_score ||= Quizzes::Leaderboard.total_score(person: @person)
      end

      def build_league
        return unless @ward && @person

        board = Quizzes::Leaderboard.call(ward: @ward, person: @person, limit: 0)
        rival = board.rival
        League.new(
          rank: board.your_rank,
          players: board.players,
          rival_name: rival&.person&.given_name,
          rival_gap: rival ? (rival.score - board.your_score.to_i) : nil,
          recent_gains: recent_league_gains
        )
      end

      def recent_league_gains
        QuizAnswer
          .joins(quiz_run: :person)
          .includes(quiz_run: :person)
          .where(quiz_runs: { game_session_id: nil })
          .where(people: { ward_id: @ward.id })
          .where(created_at: (@at - 7.days)..@at)
          .where("quiz_answers.points_awarded > 0")
          .order(created_at: :desc, id: :desc)
          .limit(3)
          .map do |answer|
            gain_person = answer.quiz_run.person
            Gain.new(
              name: gain_person.given_name,
              points: answer.points_awarded,
              at: answer.created_at,
              avatar_key: gain_person.avatar_key
            )
          end
      end

      def current_pack
        id = @open_run&.pack_id.presence || @world.current_pack_id
        @world.packs.find { |pack| pack.id == id } || @world.packs.find { |pack| pack.id == @world.current_pack_id }
      end

      def build_player
        score = total_score
        current = Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first
        nxt = Team::RANKS.find { |threshold, _, _| score < threshold }
        rank_key = current[1]
        Player.new(
          name: @person&.given_name,
          rank_key:,
          level: street_rank_level(score),
          xp_now: score,
          xp_next: nxt&.first,
          xp_progress: street_rank_progress(score),
          crowns: score,
          streak: Quizzes::Streak.call(person_id: @person&.id, device_digest: @digest).days,
          avatar_key: @person&.avatar_key,
          guest: @person.nil?
        )
      end

      def street_rank_level(score)
        current = Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first
        (Team::RANKS.index { |threshold, _, _| threshold == current[0] } || 0) + 1
      end

      def street_rank_progress(score)
        current = Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first
        nxt = Team::RANKS.find { |threshold, _, _| score < threshold }
        return 100 unless nxt

        span = nxt[0] - current[0]
        return 100 if span <= 0

        (((score - current[0]) * 100) / span).clamp(0, 100)
      end

      def build_hero
        pack_view = current_pack
        return Hero.new(step_n: 1, step_total: QuizDefinition::QUESTIONS_PER_PACK, reward: 0, method: :get, path: @helpers.jugar_path) unless pack_view

        pack = pack_view.pack
        run = hero_run(pack_view)
        step_n = run&.open? ? run.position : 1
        Hero.new(
          kicker: pack.copy(:kicker),
          title: pack.copy(:title),
          lede: pack.copy(:lede),
          step_n:,
          step_total: pack.questions.size,
          reward: remaining_points(pack, run),
          still: still_src(pack, position: step_n),
          method: run&.open? ? :get : :post,
          path: run&.open? ? @helpers.jugar_path : @helpers.street_pack_start_path(pack.id)
        )
      end

      def hero_run(pack_view)
        return @open_run if @open_run && @open_run.pack_id == pack_view.id

        pack_view.open_run
      end

      def remaining_points(pack, run)
        return Quizzes::StreakReward.max_pack_score(question_count: pack.questions.size) unless run&.open?

        Quizzes::StreakReward.remaining_potential(run:)
      end

      def still_src(pack, position: 1)
        question = pack.question_at(position) || pack.question_at(1)
        image = question.presentation["image"]
        return if image.blank?

        rel = image.to_s.delete_prefix("/")
        rel = "media/#{rel}" unless rel.start_with?("media/")
        if (asset = Frontend::MediaManifest.fetch_source(rel))
          return asset.fetch("variants").fetch("webp").last.fetch("src")
        end

        "/#{rel}" if Rails.public_path.join(rel).file?
      end

      def build_voyage
        packs = @world.packs
        playing = current_pack
        idx = packs.index(playing) || packs.index { |pack| pack.id == @world.current_pack_id } || 0
        Voyage.new(
          previous: slide_for(:previous, idx.positive? ? packs[idx - 1] : nil),
          current: slide_for(:current, packs[idx]),
          next: slide_for(:next, packs[idx + 1])
        )
      end

      def slide_for(kind, pack_view)
        return unless pack_view

        pack = pack_view.pack
        run = kind == :current ? hero_run(pack_view) : open_run_for(pack_view)
        playable = pack_view.state != :locked
        Slide.new(
          kind:,
          title: pack.copy(:title),
          kicker: pack.copy(:kicker),
          lede: pack.copy(:lede),
          still: still_src(pack, position: slide_step(pack_view, run)),
          state: pack_view.state,
          step_n: slide_step(pack_view, run),
          step_total: pack.questions.size,
          reward: remaining_points(pack, run),
          method: run&.open? ? :get : :post,
          path: playable ? play_path(pack, run) : nil
        )
      end

      def open_run_for(pack_view)
        pack_view.open_run
      end

      def slide_step(pack_view, run)
        return run.position if run&.open?
        return pack_view.pack.questions.size if pack_view.state == :finished

        1
      end

      def play_path(pack, run)
        run&.open? ? @helpers.jugar_path : @helpers.street_pack_start_path(pack.id)
      end

      def live_night
        return @live_night if defined?(@live_night)

        @live_night = pick_live_night
      end

      def pick_live_night
        return unless @ward

        scope = GameSession.active.joins(:ward).merge(Ward.listed).where(ward_id: @ward.id)
        playing = scope.where(starts_at: ..@at, ends_at: @at..).order(starts_at: :desc, id: :desc).first
        return playing if playing

        window_end = (@at + LIVE_WINDOW).end_of_day
        upcoming = scope.where(starts_at: @at..window_end)
          .order(:starts_at, :id)
        ward_hit = @ward ? upcoming.find { |night| night.ward_id == @ward.id } : nil
        ward_hit || upcoming.first
      end

      def live_theme_id
        live_night&.primary_quiz_pack&.id
      end

      def backdrop
        @backdrop ||= Hubs::Backdrop.call(
          at: @at,
          theme_id: live_theme_id,
          pack_id: current_pack&.id,
          mode: active_chrome&.mode
        )
      end

      def active_chrome
        return @active_chrome if defined?(@active_chrome)

        pack_view = current_pack
        run = pack_view && hero_run(pack_view)
        position = run&.open? ? run.position : 1
        question = pack_view&.pack&.question_at(position)
        @active_chrome = question ? Quizzes::Chrome.call(question:) : nil
      end

      def backdrop_live_theme
        [ backdrop.theme.mode, backdrop.theme.atmosphere ]
      end

      def ward_discovery_path
        return @helpers.search_path(cambiar: 1) if @person

        @helpers.street_profile_path(quick: 1, fresh: 1, ward_next: 1)
      end

      def build_live
        unless @ward
          theme_mode, theme_atmosphere = backdrop_live_theme
          return Live.new(
            state: :ward_missing,
            program_path: ward_discovery_path,
            ward_pick_path: ward_discovery_path,
            still: default_live_still,
            theme_mode:,
            theme_atmosphere:
          )
        end

        night = live_night
        program = @helpers.ward_profile_path(@ward.code)
        unless night
          theme_mode, theme_atmosphere = backdrop_live_theme
          return Live.new(
            state: :none,
            program_path: program,
            still: default_live_still,
            theme_mode:,
            theme_atmosphere:
          )
        end

        title = night_quiz_title(night)
        still, theme_mode, theme_atmosphere = live_picture(night)
        if night.playing?
          return Live.new(
            state: :playing,
            starts_at: night.starts_at,
            title:,
            join_path: @helpers.night_path(night.code),
            program_path: program,
            still:,
            theme_mode:,
            theme_atmosphere:
          )
        end

        delta = night.starts_at - @at
        state = if delta <= 24.hours
          :imminent
        elsif delta <= 48.hours
          :soon
        else
          :scheduled
        end
        Live.new(
          state:,
          starts_at: night.starts_at,
          title:,
          program_path: program,
          still:,
          theme_mode:,
          theme_atmosphere:
        )
      end

      def night_quiz_title(night)
        night.primary_quiz_pack.copy(:title)
      end

      def live_picture(night)
        question = night.primary_quiz_pack.question_at(1)
        image = question.presentation["image"]
        chrome = Quizzes::Chrome.call(question:)
        relative = image.to_s.start_with?("media/") ? image.to_s : "media/#{image}"
        if (src = responsive_src(relative))
          return [ src, chrome.mode.presence || live_mode(src, "light"), chrome.atmosphere.presence || "peaceful" ]
        end

        [ nil, chrome.mode.presence || "light", chrome.atmosphere.presence || "peaceful" ]
      end

      def responsive_src(relative_path)
        if (asset = Frontend::MediaManifest.fetch_source(relative_path))
          return asset.fetch("variants").fetch("webp").last.fetch("src")
        end

        "/#{relative_path.delete_prefix('/')}" if Rails.public_path.join(relative_path.delete_prefix("/")).file?
      end

      def default_live_still
        responsive_src(CHAPEL_STILL)
      end

      def live_mode(src, fallback)
        Quizzes::Chrome.mode_for(src).presence || (Hubs::Backdrop::MODES.include?(fallback.to_s) ? fallback.to_s : "light")
      end

      # Editorial teams can publish next year's programme before its first
      # week begins. The Hub therefore selects the published week that is
      # actually active today, rather than assuming the greatest year is the
      # one a player should see now.
      def current_study_week
        @current_study_week ||= StudyUnit
          .joins(:study_program)
          .includes(:study_program)
          .where(
            study_programs: { status: "published" },
            study_units: { kind: "week", status: "published" }
          )
          .where("study_units.starts_on <= ? AND study_units.ends_on >= ?", @at.to_date, @at.to_date)
          .order(Arel.sql("study_programs.year DESC"), Arel.sql("study_units.position ASC"), Arel.sql("study_units.id ASC"))
          .first
      end

      def build_study
        week = current_study_week
        quiz = week&.published_quiz
        return unless week && quiz

        Study.new(
          week:,
          weekly_reading_cards: Hubs::WeeklyReadingCards.call(person: @person, week:, quiz:, locale: I18n.locale)
        )
      end
  end
end
