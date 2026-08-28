module Quizzes
  class World
    CATEGORY_MAP = {
      "coronas" => "rois",
      "placas" => "sagesse",
      "hermanas" => "sagesse",
      "abish" => "heros",
      "profetas" => "prophetes",
      "jehova" => "sagesse",
      "nazareno" => "heros",
      "moises" => "prophetes",
      "abraham" => "heros",
      "kolob" => "sagesse",
      "premortal" => "sagesse",
      "exaltacion" => "sagesse",
      "jose" => "heros",
      "inicios" => "sagesse",
      "pruebas_profetas" => "prophetes",
      "pruebas_heroes" => "heros",
      "milagros" => "heros",
      "apocalipsis" => "prophetes",
      "segunda_venida" => "prophetes",
      "milenio" => "prophetes",
      "perdido_encontrado" => "sagesse",
      "secretos_reino" => "sagesse",
      "amar_projimo" => "heros",
      "velar_servir" => "sagesse",
      "sobre_roca" => "sagesse",
      "simbolos_mormon" => "sagesse",
      "parabolas_profetas" => "prophetes",
      "improbables" => "heros"
    }.freeze

    TIER_BOUNDARIES = [
      { key: "debutant", start: 0, end: 9, color: "green" },
      { key: "apprenti", start: 10, end: 19, color: "blue" },
      { key: "disciple", start: 20, end: 29, color: "purple" },
      { key: "maitre", start: 30, end: 39, color: "orange", collapsed: true },
      { key: "legende", start: 40, end: 49, color: "red", collapsed: true }
    ].freeze

    TIER_COLORS = {
      debutant: "green", apprenti: "blue", disciple: "purple",
      maitre: "orange", legende: "red"
    }.freeze

    TIER_ORDER = { debutant: 0, apprenti: 1, disciple: 2, maitre: 3, legende: 4 }

    PackView = Struct.new(
      :id, :pack, :state, :stars, :best_score, :open_run_id, :index, :trail,
      :category, keyword_init: true
    )
    Path = Struct.new(:finished, :current, :locked, keyword_init: true)
    Result = Struct.new(:packs, :current_pack_id, :current_run, :path, keyword_init: true)
    Tier = Struct.new(:key, :start, :end, :color, :collapsed, :label_key, :packs, :flags, keyword_init: true)

    def self.call(device_digest:, person_id: nil)
      new(device_digest:, person_id:).call
    end

    def initialize(device_digest:, person_id: nil)
      @digest = device_digest.to_s
      @person_id = person_id
      @catalog = QuizDefinition.catalog
      @pack_ids = @catalog.pack_ids
    end

    def call
      finished = finished_by_pack
      open_runs = scoped.open_runs.index_by(&:pack_id)
      next_id = next_playable_pack_id(finished, open_runs)
      packs = @pack_ids.each_with_index.map do |pack_id, index|
        build_pack_view(pack_id, index, finished, open_runs, next_id)
      end
      current_pack_id = open_runs.keys.last || next_id || @pack_ids.reverse.find { |id| finished.key?(id) }
      current_run = current_pack_id && (open_runs[current_pack_id] || scoped.where(pack_id: current_pack_id).order(:id).last)
      Result.new(packs:, current_pack_id:, current_run:, path: build_path(packs, current_pack_id))
    end

    def self.category_for(pack_id)
      CATEGORY_MAP[pack_id.to_s]
    end

    def self.tier_for(index)
      TIER_BOUNDARIES.reverse_each.find { |t| index >= t[:start] && index <= t[:end] }
    end

    def self.tier_label_key(tier_key)
      "street.#{tier_key}_label"
    end

    private

      def scoped
        QuizRun.adventure.where(device_digest: @digest, person_id: @person_id)
      end

      def finished_by_pack
        scoped.finished.group_by(&:pack_id).transform_values do |runs|
          best = runs.max_by(&:score)
          { run: best, stars: Stars.call(score: best.score) }
        end
      end

      def next_playable_pack_id(finished, open_runs)
        @pack_ids.find do |pack_id|
          idx = @pack_ids.index(pack_id)
          unlocked = idx.zero? || finished.key?(@pack_ids[idx - 1])
          unlocked && !finished.key?(pack_id) && !open_runs.key?(pack_id)
        end
      end

      def build_pack_view(pack_id, index, finished, open_runs, next_id)
        pack = @catalog.find_pack(pack_id)
        unlocked = index.zero? || finished.key?(@pack_ids[index - 1])
        fin = finished[pack_id]
        open = open_runs[pack_id]
        state = if open
          :open
        elsif !unlocked
          :locked
        elsif fin
          :finished
        elsif pack_id == next_id
          :current
        else
          :available
        end
        trail = if open
          Trail.call(run: open)
        elsif fin
          Trail.call(run: fin[:run])
        else
          []
        end
        tier = self.class.tier_for(index)
        PackView.new(
          id: pack_id,
          pack:,
          state:,
          stars: fin&.dig(:stars) || 0,
          best_score: fin&.dig(:run)&.score,
          open_run_id: open&.id,
          index:,
          trail:,
          category: self.class.category_for(pack_id)
        )
      end

      def build_path(packs, current_pack_id)
        idx = packs.index { |pack| pack.id == current_pack_id }
        idx ||= packs.index { |pack| pack.state.in?(%i[current open]) }
        idx ||= packs.rindex { |pack| pack.state == :finished } || 0
        Path.new(
          finished: idx.positive? ? packs[idx - 1] : nil,
          current: packs[idx],
          locked: packs[idx + 1]
        )
      end
  end
end
