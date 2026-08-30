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
        move_notifications!
        move_devices!
        move_quiz_runs!
        move_study_runs!
        move_reading_progresses!
        move_scripture_reads!
        move_scripture_highlights!
        move_scripture_reader_preference!
        move_scripture_reading_progresses!
        move_scripture_library!
        move_scripture_circle_attribution!
        move_duel_invitations!
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

      def move_notifications!
        merge_notification_preferences!
        merge_notification_prompt_states!
        @source.web_push_subscriptions.update_all(person_id: @keeper.id, updated_at: Time.current)
        @source.notification_deliveries.update_all(person_id: @keeper.id, updated_at: Time.current)
        normalize_push_subscriptions!
      end

      def merge_notification_preferences!
        source_preference = @source.notification_preference
        return unless source_preference

        keeper_preference = @keeper.notification_preference
        unless keeper_preference
          source_preference.update!(person: @keeper)
          return
        end

        attributes = {
          challenges_enabled: keeper_preference.challenges_enabled? || source_preference.challenges_enabled?,
          challenges_enabled_at: [ keeper_preference.challenges_enabled_at, source_preference.challenges_enabled_at ].compact.min,
          verses_enabled: keeper_preference.verses_enabled? || source_preference.verses_enabled?,
          verses_enabled_at: [ keeper_preference.verses_enabled_at, source_preference.verses_enabled_at ].compact.min
        }
        if !keeper_preference.verses_enabled? && source_preference.verses_enabled?
          attributes.merge!(source_preference.slice(:verse_frequency, :verse_local_time, :quiet_hours_start, :quiet_hours_end))
        end
        keeper_preference.update!(attributes)
        source_preference.destroy!
      end

      def merge_notification_prompt_states!
        @source.person_devices.includes(:notification_prompt_states).find_each do |source_device|
          keeper_device = @keeper.person_devices.find_by(device_token: source_device.device_token)
          next unless keeper_device

          source_device.notification_prompt_states.each do |source_state|
            keeper_state = keeper_device.notification_prompt_states.find_by(category: source_state.category)
            if keeper_state
              newest = [ keeper_state, source_state ].max_by(&:updated_at)
              keeper_state.update!(newest.slice(:last_offered_at, :last_result, :snoozed_until, :offer_context)) if newest == source_state
              source_state.destroy!
            else
              source_state.update!(person_device: keeper_device)
            end
          end
        end
      end

      def normalize_push_subscriptions!
        @keeper.web_push_subscriptions.active.group_by(&:device_token_digest).each_value do |subscriptions|
          subscriptions.sort_by(&:updated_at).reverse.drop(1).each(&:revoke!)
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

      def move_scripture_reader_preference!
        source_preference = @source.scripture_reader_preference
        return unless source_preference

        keeper_preference = @keeper.scripture_reader_preference
        unless keeper_preference
          source_preference.update!(person: @keeper)
          return
        end

        if source_preference.updated_at > keeper_preference.updated_at
          keeper_preference.update!(source_preference.reader_attributes)
        end
        source_preference.destroy!
      end

      def move_scripture_reading_progresses!
        @source.scripture_reading_progresses.find_each do |progress|
          existing = @keeper.scripture_reading_progresses.find_by(
            reference: progress.reference,
            locale: progress.locale
          )
          unless existing
            progress.update!(person: @keeper)
            next
          end

          latest = [ existing, progress ].max_by(&:last_opened_at)
          existing.update!(
            first_opened_at: [ existing.first_opened_at, progress.first_opened_at ].min,
            last_opened_at: [ existing.last_opened_at, progress.last_opened_at ].max,
            last_verse: latest.last_verse,
            last_offset: latest.last_offset,
            progress_ratio: [ existing.progress_ratio, progress.progress_ratio ].max,
            completed_at: [ existing.completed_at, progress.completed_at ].compact.min
          )
          progress.destroy!
        end
      end

      def move_scripture_library!
        move_scripture_tags!
        move_scripture_notebooks!
        @source.scripture_marks.update_all(person_id: @keeper.id, updated_at: Time.current)
      end

      def move_scripture_tags!
        @source.scripture_tags.find_each do |tag|
          existing = @keeper.scripture_tags.find_by(normalized_name: tag.normalized_name)
          unless existing
            tag.update!(person: @keeper)
            next
          end

          tag.scripture_mark_taggings.find_each do |tagging|
            duplicate = ScriptureMarkTagging.exists?(
              scripture_mark_id: tagging.scripture_mark_id,
              scripture_tag_id: existing.id
            )
            duplicate ? tagging.destroy! : tagging.update_columns(scripture_tag_id: existing.id, updated_at: Time.current)
          end
          tag.destroy!
        end
      end

      def move_scripture_notebooks!
        keeper_notebooks = @keeper.scripture_notebooks.to_a
        @source.scripture_notebooks.find_each do |notebook|
          normalized_title = notebook.title.to_s.squish.downcase
          existing = keeper_notebooks.find { |candidate| candidate.title.to_s.squish.downcase == normalized_title }
          unless existing
            notebook.update!(person: @keeper)
            keeper_notebooks << notebook
            next
          end

          notebook.scripture_notebook_entries.find_each do |entry|
            duplicate = ScriptureNotebookEntry.exists?(
              scripture_notebook_id: existing.id,
              scripture_mark_id: entry.scripture_mark_id
            )
            duplicate ? entry.destroy! : entry.update_columns(scripture_notebook_id: existing.id, updated_at: Time.current)
          end
          notebook.destroy!
        end
      end

      def move_scripture_circle_attribution!
        now = Time.current
        affected_proposal_ids = @source.scripture_circle_moderation_ballots.pluck(
          :scripture_circle_moderation_proposal_id
        )

        @source.scripture_circle_posts.update_all(person_id: @keeper.id, updated_at: now)
        ScriptureCirclePostRevision.where(editor_person_id: @source.id)
          .update_all(editor_person_id: @keeper.id)
        @source.scripture_circle_moderation_proposals
          .update_all(proposer_person_id: @keeper.id, updated_at: now)
        ScriptureCircleModerationEvent.where(actor_person_id: @source.id)
          .update_all(actor_person_id: @keeper.id)

        @source.scripture_circle_moderation_ballots.find_each do |ballot|
          existing = ScriptureCircleModerationBallot.find_by(
            scripture_circle_moderation_proposal_id: ballot.scripture_circle_moderation_proposal_id,
            voter_person_id: @keeper.id
          )
          if existing
            if ballot.cast_at > existing.cast_at
              existing.update_columns(choice: ballot.choice, cast_at: ballot.cast_at, updated_at: now)
            end
            ballot.scripture_circle_moderation_ballot_revisions.update_all(
              scripture_circle_moderation_ballot_id: existing.id,
              voter_person_id: @keeper.id
            )
            ballot.destroy!
          else
            ballot.update_columns(voter_person_id: @keeper.id, updated_at: now)
            ballot.scripture_circle_moderation_ballot_revisions
              .update_all(voter_person_id: @keeper.id)
          end
        end

        ScriptureCircleModerationBallotRevision.where(voter_person_id: @source.id)
          .update_all(voter_person_id: @keeper.id)
        refresh_scripture_moderation_counts!(affected_proposal_ids)
      end

      def refresh_scripture_moderation_counts!(proposal_ids)
        ScriptureCircleModerationProposal.where(id: proposal_ids).find_each do |proposal|
          choices = proposal.scripture_circle_moderation_ballots.group(:choice).count
          proposal.update_columns(
            yes_count: choices.fetch("yes", 0),
            no_count: choices.fetch("no", 0),
            valid_ballot_count: choices.values.sum,
            updated_at: Time.current
          )
        end
      end

      def move_duels!
        collapsed = StreetDuel.where(
          "(challenger_person_id = :source AND opponent_person_id = :keeper) OR " \
            "(challenger_person_id = :keeper AND opponent_person_id = :source)",
          source: @source.id,
          keeper: @keeper.id
        )
        collapsed.find_each do |duel|
          duel.duel_invitations.update_all(street_duel_id: nil, updated_at: Time.current)
          ViralEvent.where(street_duel_id: duel.id).update_all(street_duel_id: nil, updated_at: Time.current)
          NotificationDelivery.where(subject: duel).update_all(
            subject_type: nil, subject_id: nil, status: "cancelled",
            cancelled_at: Time.current, updated_at: Time.current
          )
          StreetDuel.where(rematch_of_id: duel.id).update_all(rematch_of_id: nil, updated_at: Time.current)
          duel.delete
        end

        StreetDuel.where("challenger_person_id = :id OR opponent_person_id = :id", id: @source.id)
          .order(:id).find_each do |duel|
            challenger_id = duel.challenger_person_id == @source.id ? @keeper.id : duel.challenger_person_id
            opponent_id = duel.opponent_person_id == @source.id ? @keeper.id : duel.opponent_person_id
            low, high = [ challenger_id, opponent_id ].sort
            duplicate = StreetDuel.active.where(pair_low_person_id: low, pair_high_person_id: high).where.not(id: duel.id).first
            duel.status = "archived" if duplicate && duel.active?
            duel.update!(
              challenger_person_id: challenger_id,
              opponent_person_id: opponent_id,
              pair_low_person_id: low,
              pair_high_person_id: high
            )
          end
      end

      def move_duel_invitations!
        now = Time.current
        DuelInvitation.where(challenger_person_id: @source.id).find_each do |invitation|
          if invitation.recipient_person_id == @keeper.id
            invitation.update!(
              challenger_person: @keeper, recipient_person: nil,
              status: "revoked", revoked_at: invitation.revoked_at || now
            )
          else
            invitation.update!(challenger_person: @keeper)
          end
        end
        DuelInvitation.where(recipient_person_id: @source.id).find_each do |invitation|
          if invitation.challenger_person_id == @keeper.id
            invitation.update!(
              recipient_person: nil, status: "revoked",
              revoked_at: invitation.revoked_at || now
            )
          else
            invitation.update!(recipient_person: @keeper)
          end
        end
        DuelInvitation.where(claimed_by_person_id: @source.id)
          .update_all(claimed_by_person_id: @keeper.id, updated_at: now)
      end
  end
end
