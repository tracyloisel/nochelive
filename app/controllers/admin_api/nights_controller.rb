module AdminApi
  class NightsController < BaseController
    def create
      ward = find_ward
      night = GameSession.transaction do
        configuration = configuration_attributes(required_starts_at: true)
        Nights::Start.call(
          ward:,
          quiz_ids: quiz_ids(required: true),
          starts_at: configuration.fetch(:starts_at),
          duration_hours: configuration.fetch(:duration_hours, GameSession::DEFAULT_DURATION_HOURS)
        )
      end
      night.broadcast_state
      admin_audit!("create_night", ward_id: ward.id, night_id: night.id)
      render json: { night: night_json(night) }, status: :created
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    def update
      ward = find_ward
      night = ward.game_sessions.find_by!(code: GameSession.normalize_code(params[:session_code]))
      Nights::Configure.call(night:, attributes: configuration_attributes)
      admin_audit!("update_night", ward_id: ward.id, night_id: night.id)
      render json: { night: night_json(night) }
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    def finish
      ward = find_ward
      night = ward.game_sessions.find_by!(code: GameSession.normalize_code(params[:session_code]))
      Nights::Close.call(night:)
      admin_audit!("finish_night", ward_id: ward.id, night_id: night.id)
      render json: { night: night_json(night) }
    end

    private

      def find_ward
        Ward.find_by!(code: Ward.normalize_code(params[:ward_code]))
      end

      def configuration_attributes(required_starts_at: false)
        attributes = {}
        if params.key?(:starts_at)
          attributes[:starts_at] = Time.iso8601(params[:starts_at].to_s)
        elsif required_starts_at
          raise ArgumentError, "starts_at is required and must be an ISO 8601 timestamp"
        end

        attributes[:quiz_pack_ids] = quiz_ids if params.key?(:quiz_ids)
        attributes[:duration_hours] = parsed_duration_hours if params.key?(:duration_hours)
        attributes
      end

      def parsed_duration_hours
        Integer(params[:duration_hours])
      rescue TypeError, ArgumentError
        raise ArgumentError, "duration_hours must be between 1 and 8"
      end

      def quiz_ids(required: false)
        unless params.key?(:quiz_ids)
          raise ArgumentError, "quiz_ids is required" if required
          return nil
        end

        ids = Array(params[:quiz_ids]).map { |id| id.to_s.strip }.reject(&:blank?)
        raise ArgumentError, "quiz_ids must contain at least one quiz" if ids.empty?
        ids
      end

      def night_json(night)
        {
          id: night.id,
          ward: { code: night.ward.code, name: night.ward.name },
          code: night.code,
          status: night.status,
          starts_at: night.starts_at.iso8601,
          ends_at: night.ends_at.iso8601,
          duration_hours: night.duration_hours,
          quiz_ids: night.quiz_pack_ids,
          quizzes: night.quiz_packs.map do |pack|
            {
              id: pack.id,
              title: pack.copy(:title),
              question_count: pack.questions.size,
              artwork: pack.questions.first&.presentation&.fetch("image", nil)
            }
          end,
          paths: {
            canonical: "/s/#{night.code}",
            players: "/s/#{night.code}/name",
            play: "/s/#{night.code}/play"
          },
          created_at: night.created_at.iso8601,
          updated_at: night.updated_at.iso8601
        }
      end
  end
end
