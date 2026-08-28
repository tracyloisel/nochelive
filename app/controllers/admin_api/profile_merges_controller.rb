module AdminApi
  class ProfileMergesController < BaseController
    def preview
      ward, first, second = merge_records
      keeper, source = oldest_first(first, second)
      confirmation = IdentityTransfer.issue!(
        "action" => "admin_profile_merge",
        "ward_id" => ward.id,
        "keeper_id" => keeper.id,
        "source_id" => source.id
      )
      render json: { preview: merge_json(ward, keeper, source), confirmation: }
    rescue People::Error => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    def create
      payload = IdentityTransfer.consume!(params[:confirmation])
      raise People::Error.new(:merge_confirmation, "Invalid merge confirmation") unless payload["action"] == "admin_profile_merge"

      ward = Ward.find(payload.fetch("ward_id"))
      keeper = ward.people.find(payload.fetch("keeper_id"))
      source = ward.people.find(payload.fetch("source_id"))
      People::Merge.call(keeper:, source:)
      admin_audit!("merge_profiles", ward_id: ward.id, keeper_id: keeper.id, source_id: source.id)
      render json: { merged: true, keeper_id: keeper.id, removed_id: source.id }
    rescue IdentityTransfer::InvalidToken, ActiveRecord::RecordNotFound, KeyError, People::Error => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    private

      def merge_records
        ward = Ward.find_by!(code: Ward.normalize_code(params[:ward_code]))
        first = ward.people.find(params[:first_id])
        second = ward.people.find(params[:second_id])
        raise People::Error.new(:same, I18n.t("errors.people.merge_same")) if first == second
        unless first.given_name_key == second.given_name_key
          raise People::Error.new(:merge_name, I18n.t("errors.people.merge_name"))
        end
        [ ward, first, second ]
      end

      def oldest_first(first, second)
        [ first, second ].sort_by { |person| [ person.created_at, person.id ] }
      end

      def merge_json(ward, keeper, source)
        scores = Quizzes::Leaderboard.pack_best_totals(ward:)
        {
          ward: { id: ward.id, code: ward.code, name: ward.name },
          keeper: person_json(keeper, scores),
          source: person_json(source, scores),
          effect: "The oldest profile is kept; all supported activity is transferred before deletion."
        }
      end

      def person_json(person, scores)
        {
          id: person.id,
          name: person.display_name,
          avatar: person.avatar_key,
          points: scores[person.id].to_i,
          created_at: person.created_at.iso8601
        }
      end
  end
end
