module Hubs
  class Screen
    Player = Struct.new(
      :name, :rank_key, :rank_label, :level, :xp_now, :xp_next, :next_rank_key, :xp_progress,
      :crowns, :streak, :avatar_key, :guest, keyword_init: true
    )
    Hero = Struct.new(
      :kicker, :title, :lede, :step_n, :step_total, :reward, :still,
      :method, :path, :pack_id, keyword_init: true
    )
    Slide = Struct.new(
      :kind, :title, :kicker, :lede, :still, :state,
      :step_n, :step_total, :reward, :method, :path,
      keyword_init: true
    )
    Voyage = Struct.new(:previous, :current, :next, keyword_init: true)
    Live = Struct.new(
      :state, :starts_at, :title, :join_path, :program_path, :still, :hosts,
      :theme_mode, :theme_atmosphere, :ward_pick_path,
      keyword_init: true
    )
    LIVE_STAGE_STILL = "media/nights/noche_live_stage_v2.png"
    CHAPEL_STILL = "media/church/worship.jpg"
    LIVE_WINDOW = 14.days
    Challenge = Struct.new(
      :phase, :waiting_for, :other_name, :other_display_name, :you_score, :other_score, :token, :play_path, :path,
      :you_avatar_key, :other_avatar_key, :other_streak, keyword_init: true
    ) do
      def scored?
        !you_score.nil? && !other_score.nil?
      end
    end
    OnlineRow = Struct.new(
      :person_id, :name, :avatar_key, :level, :crowns, :playing_title, :action, keyword_init: true
    )
    ProgressNode = Struct.new(:title, :still, :state, :focus, keyword_init: true)
    Progress = Struct.new(
      :finished, :unlocked, :total, :current_n, :current_title, :current_pack_still, :nodes,
      :study_completed, :study_total,
      keyword_init: true
    )
    Study = Struct.new(:week, :quiz, :run, :progress, :players, keyword_init: true)
    MapProgress = Struct.new(:total_packs, :questions_per_pack, :finished, :completed_packs, :rewards, :tiers, :current_tier_key, :finished_count, keyword_init: true)
    Community = Struct.new(:players_this_month, :questions, :wards, keyword_init: true)
    Result = Struct.new(
      :player, :hero, :voyage, :live, :challenge, :online, :online_count, :progress, :study, :community, :pulse, :backdrop,
      keyword_init: true
    )

    def self.call(device_digest:, person: nil, ward: nil, at: Time.current, challenge: nil, open_run: nil,
      random_backdrop: false, previous_backdrop_id: nil, world: nil, pulse: nil)
      new(device_digest:, person:, ward:, at:, challenge:, open_run:, random_backdrop:, previous_backdrop_id:, world:, pulse:).call
    end

    def initialize(device_digest:, person: nil, ward: nil, at: Time.current, challenge: nil, open_run: nil,
      random_backdrop: false, previous_backdrop_id: nil, world: nil, pulse: nil)
      @digest = device_digest.to_s
      @person = person
      @ward = ward
      @at = at
      @challenge = challenge
      @open_run = open_run
      @random_backdrop = random_backdrop
      @previous_backdrop_id = previous_backdrop_id
      @world = world || Quizzes::World.call(device_digest: @digest, person_id: @person&.id)
      @pulse = pulse
      @helpers = Rails.application.routes.url_helpers
    end

    def call
      Result.new(
        player: build_player,
        hero: build_hero,
        voyage: build_voyage,
        live: build_live,
        challenge: build_challenge,
        online: build_online,
        online_count: online_scope.count,
        progress: build_progress,
        study: build_study,
        community: build_community,
        pulse: pulse,
        backdrop:
      )
    end

    private

      def total_score
        return 0 unless @ward && @person

        @total_score ||= Quizzes::Leaderboard.total_score(person: @person)
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
          rank_label: Team.rank_label_for(rank_key),
          level: street_rank_level(score),
          xp_now: score,
          xp_next: nxt&.first,
          next_rank_key: nxt&.[](1),
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
          still: still_src(pack),
          method: run&.open? ? :get : :post,
          path: run&.open? ? @helpers.jugar_path : @helpers.street_pack_start_path(pack.id),
          pack_id: pack.id
        )
      end

      def hero_run(pack_view)
        return @open_run if @open_run && @open_run.pack_id == pack_view.id

        pack_view.open_run
      end

      def remaining_points(pack, run)
        curve = QuizDefinition::CURVE_POINTS
        return curve.sum unless run&.open?

        idx = run.position - 1
        idx += 1 if run.settled?
        curve.drop(idx).sum
      end

      def still_src(pack)
        image = pack.question_at(1).presentation["image"]
        return if image.blank?

        rel = image.to_s.delete_prefix("/")
        rel = "media/#{rel}" unless rel.start_with?("media/")
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
          still: still_src(pack),
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

        scope = GameSession.joins(:ward).merge(Ward.listed).includes(:missionaries)
        scope = scope.where(ward_id: @ward.id) if @ward
        playing = scope.where(status: "playing").order(:starts_at, :id).first
        return playing if playing

        window_end = (@at + LIVE_WINDOW).end_of_day
        upcoming = scope.where.not(status: "finished")
          .where(starts_at: @at.beginning_of_day..window_end)
          .order(:starts_at, :id)
        ward_hit = @ward ? upcoming.find { |night| night.ward_id == @ward.id } : nil
        ward_hit || upcoming.first
      end

      def live_theme_id
        live_night&.theme_id
      end

      def backdrop
        @backdrop ||= Hubs::Backdrop.call(
          at: @at,
          theme_id: live_theme_id,
          pack_id: current_pack&.id,
          randomize: @random_backdrop,
          exclude_id: @previous_backdrop_id
        )
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
            hosts: [],
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
            hosts: [],
            theme_mode:,
            theme_atmosphere:
          )
        end

        title = night_theme_title(night)
        still, theme_mode, theme_atmosphere = live_picture(night)
        hosts = night.missionaries.map(&:name)
        if night.playing?
          return Live.new(
            state: :playing,
            starts_at: night.starts_at,
            title:,
            join_path: @helpers.night_name_path(night.code),
            program_path: program,
            still:,
            hosts:,
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
          hosts:,
          theme_mode:,
          theme_atmosphere:
        )
      end

      def night_theme_title(night)
        night.definition.theme.copy(:title)
      rescue GameDefinition::Error
        night.theme_title
      end

      def live_picture(night)
        if night.poster_path.present? && (src = @helpers.night_poster_src(night)).present?
          return [ src, live_mode(src, "light"), "peaceful" ]
        end

        # The LIVE card advertises a game-show night, not another chapter still.
        # Its dedicated stage art deliberately stays independent from the hub
        # backdrop and the current street-quiz painting.
        if Rails.public_path.join(LIVE_STAGE_STILL).file?
          theme_mode, theme_atmosphere = backdrop_live_theme
          return [ "/#{LIVE_STAGE_STILL}", theme_mode, theme_atmosphere ]
        end
        if Rails.public_path.join(CHAPEL_STILL).file?
          return [ "/#{CHAPEL_STILL}", "light", "peaceful" ]
        end

        poster = "media/nights/#{night.theme_file_id}.jpg"
        if Rails.public_path.join(poster).file?
          src = "/#{poster}"
          return [ src, live_mode(src, "light"), "peaceful" ]
        end

        [ nil, "light", "peaceful" ]
      end

      def live_still?(src)
        src.present? && src != Hubs::Backdrop::FALLBACK_SRC
      end

      def live_mode(src, fallback)
        Quizzes::Chrome.mode_for(src).presence || (Hubs::Backdrop::MODES.include?(fallback.to_s) ? fallback.to_s : "light")
      end

      def build_challenge
        screen = @challenge
        return unless screen&.duel

        duel = screen.duel
        other = other_person(duel)
        you_score, other_score = scores_for(duel)
        play_path = screen.phase == :play ? @helpers.jugar_path : nil
        Challenge.new(
          phase: screen.phase,
          waiting_for: screen.waiting_for,
          other_name: other&.given_name,
          other_display_name: other&.display_name,
          you_score:,
          other_score:,
          token: duel.token,
          play_path:,
          path: play_path || @helpers.street_challenge_path(duel.token),
          you_avatar_key: @person&.avatar_key,
          other_avatar_key: other&.avatar_key,
          other_streak: streak_for(other, duel)
        )
      end

      def other_person(duel)
        return duel.opponent_person if @person&.id == duel.challenger_person_id

        duel.challenger_person
      end

      def scores_for(duel)
        return [ nil, nil ] unless duel.challenger_score && duel.opponent_score
        return [ duel.challenger_score, duel.opponent_score ] if @person&.id == duel.challenger_person_id

        [ duel.opponent_score, duel.challenger_score ]
      end

      def streak_for(person, duel)
        return unless person

        run = if person.id == duel.challenger_person_id
          duel.challenger_run
        elsif person.id == duel.opponent_person_id
          duel.opponent_run
        end
        run ||= QuizRun.finished.where(person_id: person.id, pack_id: duel.pack_id).order(:id).last
        return unless run&.finished?

        count = Quizzes::HitStreak.max_count(run:)
        count if count >= 2
      end

      def build_online
        return [] unless @ward && @person

        people = online_scope.order(:id).limit(2).to_a
        scores = Quizzes::Leaderboard.total_scores(person_ids: people.map(&:id))
        runs = QuizRun.open_runs.where(person_id: people.map(&:id)).order(:id)
        run_by_person = runs.group_by(&:person_id).transform_values(&:last)
        can_challenge = QuizRun.finished.exists?(person_id: @person.id)
        people.map do |row|
          run = run_by_person[row.id]
          playing = run && QuizDefinition.catalog.find_pack(run.pack_id).copy(:title)
          crowns = scores[row.id].to_i
          OnlineRow.new(
            person_id: row.id,
            name: row.given_name,
            avatar_key: row.avatar_key,
            level: street_rank_level(crowns),
            crowns:,
            playing_title: playing,
            action: can_challenge ? :challenge : :invite
          )
        end
      end

      def online_scope
        return Person.none unless @ward && @person

        @online_scope ||= Person.where(ward_id: @ward.id)
          .joins(:person_devices)
          .merge(PersonDevice.live)
          .where.not(id: @person.id)
          .distinct
      end

      def build_progress
        packs = @world.packs
        study_program = current_study_program
        study_total = study_program ? study_program.study_units.weeks.count : 0
        study_completed = if study_program
          study_runs
            .completed
            .joins(study_quiz_version: :study_unit)
            .where(study_units: { study_program_id: study_program.id })
            .distinct
            .count("study_units.id")
        else
          0
        end
        finished = packs.count { |pack| pack.state == :finished }
        playing = current_pack
        still_src = playing&.pack ? still_src(playing.pack) : nil
        focus_index = packs.index(playing) ||
          packs.index { |pack| pack.state.in?(%i[current open available]) } ||
          packs.rindex { |pack| pack.state == :finished } ||
          0
        Progress.new(
          finished:,
          unlocked: packs.count { |pack| pack.state != :locked },
          total: packs.size,
          current_n: packs.any? ? focus_index + 1 : 0,
          current_title: playing&.pack&.copy(:title),
          current_pack_still: still_src,
          nodes: progress_nodes(packs, focus_index),
          study_completed:,
          study_total:
        )
      end

      def study_runs
        StudyRun.where(device_digest: @digest, person_id: @person&.id)
      end

      def current_study_program
        @current_study_program ||= StudyProgram.order(year: :desc).first
      end

      def build_study
        week = current_study_program&.current_week
        quiz = week&.published_quiz
        return unless week && quiz

        runs = StudyRun.joins(:study_quiz_version).where(
          study_quiz_versions: { study_unit_id: week.id },
          device_digest: @digest,
          person_id: @person&.id
        )
        run = runs.order(
          Arel.sql("CASE study_runs.status WHEN 'completed' THEN 0 ELSE 1 END"),
          completed_at: :desc,
          updated_at: :desc
        ).first
        progress = run ? run.study_answers.count : 0
        players = StudyRun.joins(:study_quiz_version)
          .where(study_quiz_versions: { study_unit_id: week.id })
          .distinct
          .count(:person_id)
        Study.new(week:, quiz:, run:, progress:, players:)
      end

      def progress_nodes(packs, focus_index)
        return [] if packs.empty?

        size = [ 4, packs.size ].min
        start = [ [ focus_index - 2, 0 ].max, packs.size - size ].min
        packs.slice(start, size).map.with_index(start) do |pack_view, index|
          focus = index == focus_index
          state = if focus
            :current
          elsif index < focus_index || pack_view.state == :finished
            :finished
          else
            :locked
          end
          ProgressNode.new(
            title: pack_view.pack.copy(:title),
            still: still_src(pack_view.pack),
            state:,
            focus:
          )
        end
      end

      def build_community
        Community.new(
          players_this_month: pulse.players,
          questions: pulse.questions,
          wards: Ward.listed.count
        )
      end

      def pulse
        @pulse ||= Platform::Pulse.call
      end
  end
end
