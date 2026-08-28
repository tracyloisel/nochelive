module Huds
  class Present
    Combo = Struct.new(:count, :tier, :broke, :grew, :shout_key, keyword_init: true)
    Result = Struct.new(
      :kind, :guest, :name, :rank_key, :level, :avatar_key, :rank_up,
      :xp_now, :xp_next, :xp_progress,
      :pack_title, :progress_n, :progress_total, :dots,
      :crowns, :streak, :score, :combo, :last_gain, :done,
      keyword_init: true
    ) do
      def guest? = guest
      def quiz? = kind == :quiz
      def done? = done
    end

    def self.call(person: nil, ward: nil, device_digest:, rank_up: false, open_run: nil)
      new(person:, ward:, device_digest:, rank_up:, open_run:).call
    end

    def self.from_screen(screen:, rank_up: false)
      player = screen.player
      hero = screen.hero
      total = hero&.step_total.to_i
      position = hero&.step_n.to_i
      Result.new(
        kind: :street,
        guest: player.guest,
        name: player.name,
        rank_key: player.guest ? nil : player.rank_key,
        level: player.guest ? nil : player.level,
        xp_now: player.xp_now,
        xp_next: player.xp_next,
        xp_progress: player.xp_progress,
        avatar_key: player.avatar_key,
        rank_up:,
        pack_title: hero&.title,
        progress_n: position,
        progress_total: total,
        dots: player.guest ? [] : dots_for(position:, total:),
        crowns: player.crowns,
        streak: player.streak
      )
    end

    def self.quiz(person:, pack:, run:, street:, question:, quiz_standings: nil, combo: nil)
      combo ||= Quizzes::HitStreak.call(run:)
      total_score = quiz_standings&.total_score.to_i
      total = pack.questions.size
      done = street.done?
      Result.new(
        kind: :quiz,
        guest: person.blank?,
        name: person&.given_name,
        rank_key: quiz_standings&.rank_title.presence,
        level: person ? rank_level(total_score) : nil,
        avatar_key: person&.avatar_key,
        pack_title: pack.copy(:title),
        progress_n: done ? total : run.position,
        progress_total: total,
        dots: done ? Array.new(total, "is-done") : dots_for(position: run.position, total:),
        score: quiz_score(street:, run:, question:),
        last_gain: done ? street.complete&.last_gain.to_i : nil,
        done:,
        combo: Combo.new(
          count: combo.count,
          tier: combo.tier,
          broke: combo.broke,
          grew: combo.grew,
          shout_key: combo.shout_key
        )
      )
    end

    def self.dots_for(position:, total:)
      return [] if total.to_i <= 0

      total.times.map do |index|
        pos = index + 1
        if pos < position
          "is-done"
        elsif pos == position
          "is-now"
        else
          "is-next"
        end
      end
    end

    def self.rank_level(score)
      current = Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first
      (Team::RANKS.index { |threshold, _, _| threshold == current[0] } || 0) + 1
    end

    def self.quiz_score(street:, run:, question:)
      if street.done?
        [ run.score - street.complete&.last_gain.to_i, 0 ].max
      elsif street.settled? && street.answer&.correct?
        [ run.score - question.points, 0 ].max
      else
        run.score
      end
    end

    def initialize(person: nil, ward: nil, device_digest:, rank_up: false, open_run: nil)
      @person = person
      @ward = ward
      @digest = device_digest.to_s
      @rank_up = rank_up
      @open_run = open_run
    end

    def call
      world = Quizzes::World.call(device_digest: @digest, person_id: @person&.id)
      pack_view = current_pack(world)
      pack = pack_view&.pack
      run = hero_run(pack_view)
      score = total_score
      xp = xp_for(score)
      guest = @person.nil?
      position = run&.open? ? run.position : 1
      total = pack&.questions&.size.to_i
      Result.new(
        kind: :street,
        guest:,
        name: @person&.given_name,
        rank_key: guest ? nil : rank_key_for(score),
        level: guest ? nil : self.class.rank_level(score),
        xp_now: guest ? nil : score,
        xp_next: guest ? nil : xp[:next],
        xp_progress: guest ? nil : xp[:progress],
        avatar_key: @person&.avatar_key,
        rank_up: @rank_up,
        pack_title: pack&.copy(:title),
        progress_n: position,
        progress_total: total,
        dots: guest ? [] : self.class.dots_for(position:, total:),
        crowns: score,
        streak: Quizzes::Streak.call(person_id: @person&.id, device_digest: @digest).days
      )
    end

    private

      def current_pack(world)
        id = @open_run&.pack_id.presence || world.current_pack_id
        world.packs.find { |pack| pack.id == id } || world.packs.find { |pack| pack.id == world.current_pack_id }
      end

      def hero_run(pack_view)
        return @open_run if @open_run && pack_view && @open_run.pack_id == pack_view.id
        pack_view&.open_run
      end

      def total_score
        return 0 unless @ward && @person

        Quizzes::Leaderboard.total_score(person: @person)
      end

      def rank_key_for(score)
        (Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first)[1]
      end

      def xp_for(score)
        current = Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first
        nxt = Team::RANKS.find { |threshold, _, _| score < threshold }
        return { next: nil, progress: 100 } unless nxt

        span = nxt[0] - current[0]
        progress = span.positive? ? (((score - current[0]) * 100) / span).clamp(0, 100) : 100
        { next: nxt[0], progress: }
      end
  end
end
