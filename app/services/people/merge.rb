module People
  class Merge
    def self.call(keeper:, source:)
      new(keeper:, source:).call
    end

    def initialize(keeper:, source:)
      @keeper = keeper
      @source = source
    end

    def call
      raise Error.new(:ward, I18n.t("errors.people.merge_ward")) if @keeper.ward_id != @source.ward_id
      raise Error.new(:same, I18n.t("errors.people.merge_same")) if @keeper.id == @source.id

      ApplicationRecord.transaction do
        @keeper.lock!
        @source.lock!
        move_players!
        move_devices!
        move_quiz_runs!
        move_study_runs!
        move_reading_progresses!
        move_scripture_reads!
        move_scripture_highlights!
        move_duels!
        move_viral_events!
        @keeper.last_ward_team ||= @source.last_ward_team
        @keeper.save!
        @source.destroy!
      end
      @keeper
    end

    private

      def move_players!
        @source.players.find_each do |player|
          keeper_player = Player.find_by(game_session_id: player.game_session_id, person_id: @keeper.id)
          if keeper_player
            merge_player!(keeper_player, player)
          else
            player.update!(person: @keeper, name: @keeper.given_name, avatar_key: @keeper.avatar_key)
          end
        end
      end

      def merge_player!(keeper_player, source_player)
        now = Time.current
        source_player.answers.update_all(player_id: keeper_player.id, updated_at: now)
        source_player.buzzes.update_all(player_id: keeper_player.id, updated_at: now)
        PoseHold.where(player_id: source_player.id).update_all(player_id: keeper_player.id, updated_at: now)
        TapRun.where(player_id: source_player.id).update_all(player_id: keeper_player.id, updated_at: now)
        merge_ballots!(keeper_player, source_player)
        merge_cheers!(keeper_player, source_player)
        merge_team_membership!(keeper_player, source_player)
        source_player.destroy!
      end

      def merge_ballots!(keeper_player, source_player)
        source_player.ballots.find_each do |ballot|
          if Ballot.exists?(round_run_id: ballot.round_run_id, player_id: keeper_player.id)
            ballot.destroy!
          else
            ballot.update!(player: keeper_player)
          end
        end
      end

      def merge_cheers!(keeper_player, source_player)
        source_player.cheers.find_each do |cheer|
          duplicate = Cheer.exists?(
            round_run_id: cheer.round_run_id,
            player_id: keeper_player.id,
            layer_index: cheer.layer_index
          )
          duplicate ? cheer.destroy! : cheer.update_columns(player_id: keeper_player.id, updated_at: Time.current)
        end
        source_player.received_cheers.update_all(to_player_id: keeper_player.id, updated_at: Time.current)
      end

      def merge_team_membership!(keeper_player, source_player)
        membership = source_player.team_membership
        return unless membership

        if keeper_player.team_membership
          membership.destroy!
        else
          membership.update!(player: keeper_player)
        end
      end

      def move_devices!
        @source.person_devices.find_each do |row|
          if @keeper.person_devices.exists?(device_token: row.device_token)
            row.destroy!
          else
            row.update!(person: @keeper)
          end
        end
      end

      def move_viral_events!
        @source.viral_events.update_all(person_id: @keeper.id, updated_at: Time.current)
      end

      def move_quiz_runs!
        QuizRun.where(person_id: @source.id).update_all(person_id: @keeper.id, updated_at: Time.current)
      end

      def move_study_runs!
        @source.study_runs.update_all(person_id: @keeper.id, updated_at: Time.current)
      end

      def move_reading_progresses!
        @source.reading_progresses.find_each do |progress|
          existing = @keeper.reading_progresses.find_by(
            study_unit_id: progress.study_unit_id,
            reference: progress.reference
          )
          if existing
            if progress.status == "completed" && existing.status != "completed"
              existing.update!(status: "completed", completed_at: progress.completed_at)
            end
            progress.destroy!
          else
            progress.update!(person: @keeper)
          end
        end
      end

      def move_scripture_reads!
        @source.scripture_chapter_reads.update_all(person_id: @keeper.id, updated_at: Time.current)
      end

      def move_scripture_highlights!
        @source.scripture_highlights.find_each do |highlight|
          duplicate = @keeper.scripture_highlights.find_by(
            reference: highlight.reference,
            locale: highlight.locale,
            **highlight.range_attributes
          )
          if duplicate
            if duplicate.selected_text.blank? && highlight.selected_text.present?
              duplicate.update!(selected_text: highlight.selected_text)
            end
            highlight.destroy!
          else
            highlight.update!(person: @keeper)
          end
        end
      end

      def move_duels!
        StreetDuel.where(
          "(challenger_person_id = :source AND opponent_person_id = :keeper) OR " \
            "(challenger_person_id = :keeper AND opponent_person_id = :source)",
          source: @source.id,
          keeper: @keeper.id
        ).update_all(status: "archived", updated_at: Time.current)

        StreetDuel.where(challenger_person_id: @source.id)
          .update_all(challenger_person_id: @keeper.id, updated_at: Time.current)
        StreetDuel.where(opponent_person_id: @source.id)
          .update_all(opponent_person_id: @keeper.id, updated_at: Time.current)
      end
  end
end
