module AdminApi
  class NightsController < BaseController
    def create
      ward = find_ward
      night = GameSession.transaction do
        created = Nights::Start.call(ward:, theme_id: params[:theme_id].presence || "reyes_y_profetas")
        Nights::Configure.call(
          night: created,
          attributes: configuration_attributes(required_starts_at: true),
          broadcast: false
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
      Nights::Finish.call(night:)
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

        if params.key?(:presenter_locale)
          locale = params[:presenter_locale].to_s
          raise ArgumentError, "presenter_locale must be one of #{Locale::AVAILABLE.join(', ')}" unless Locale::AVAILABLE.include?(locale)
          attributes[:presenter_locale] = locale
        end
        attributes[:broadcast_delay_ms] = params[:broadcast_delay_ms] if params.key?(:broadcast_delay_ms)
        attributes[:missionary_names] = params[:missionary_names] if params.key?(:missionary_names)
        attributes[:poster_path] = params[:poster_path].presence if params.key?(:poster_path)
        attributes
      end

      def night_json(night)
        {
          id: night.id,
          ward: { code: night.ward.code, name: night.ward.name },
          code: night.code,
          status: night.status,
          starts_at: night.starts_at.iso8601,
          theme_id: night.theme_id,
          theme_title: night.theme_title,
          presenter_locale: night.presenter_locale,
          broadcast_delay_ms: night.broadcast_delay_ms,
          poster_path: night.poster_path,
          missionary_names: night.missionaries.order(:id).pluck(:name),
          paths: {
            players: "/s/#{night.code}/name",
            presenter: "/p/#{night.code}",
            public: "/public/#{night.public_token}"
          },
          created_at: night.created_at.iso8601,
          updated_at: night.updated_at.iso8601
        }
      end
  end
end
