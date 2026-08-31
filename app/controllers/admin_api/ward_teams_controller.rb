module AdminApi
  class WardTeamsController < BaseController
    def create
      ward = Ward.find_by!(code: Ward.normalize_code(params[:ward_code]))
      team = ward.ward_teams.create!(
        name: params.require(:name).to_s.strip,
        emblem: params.require(:emblem).to_s
      )
      admin_audit!("create_ward_team", ward_id: ward.id, ward_team_id: team.id)
      render json: { team: team_json(team) }, status: :created
    rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    private

      def team_json(team)
        {
          id: team.id,
          ward_code: team.ward.code,
          name: team.name,
          emblem: team.emblem,
          emblem_label: Team::EMBLEMS.fetch(team.emblem),
          created_at: team.created_at.iso8601
        }
      end
  end
end
