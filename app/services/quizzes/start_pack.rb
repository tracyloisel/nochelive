module Quizzes
  class StartPack
    class Locked < StandardError; end

    def self.call(device_digest:, pack_id:, person_id: nil, challenge: false, street_duel: nil)
      new(device_digest:, pack_id:, person_id:, challenge:, street_duel:).call
    end

    def initialize(device_digest:, pack_id:, person_id: nil, challenge: false, street_duel: nil)
      @digest = device_digest.to_s
      @pack_id = pack_id.to_s
      @person_id = person_id
      @challenge = challenge
      @street_duel = street_duel
      raise ArgumentError, "device required" if @digest.blank?
    end

    def call
      unless @challenge
        world = World.call(device_digest: @digest, person_id: @person_id)
        pack_view = world.packs.find { |p| p.id == @pack_id }
        raise Locked, "pack locked" unless pack_view && pack_view.state != :locked

        open = scoped.open_runs.find_by(pack_id: @pack_id)
        return Draw.frame(open) if open

        last = scoped.where(pack_id: @pack_id).order(:id).last
        return Draw.frame(last) if last&.open?
      end

      Draw.frame(create_run)
    end

    private

      def scoped
        QuizRun.adventure.where(device_digest: @digest, person_id: @person_id)
      end

      def create_run
        pack = QuizDefinition.catalog.find_pack(@pack_id)
        question = pack.question_at(1)
        QuizRun.create!(
          device_digest: @digest,
          person_id: @person_id,
          pack_id: @pack_id,
          position: 1,
          score: 0,
          status: "open",
          opened_at: Time.current,
          street_duel: @street_duel,
          **AskClock.opening_attrs(question)
        )
      end
  end
end
