require "digest"
require "set"

class ReplaceLegacyChallengesWithDuelCampus < ActiveRecord::Migration[8.1]
  ACTIVE_DUEL_STATUSES = %w[active one_scored].freeze

  def up
    create_duel_invitations!
    prepare_viral_events!
    expand_duels!
    migrate_legacy_duels!
    contract_duels!
    finalize_viral_events!
    migrate_notification_prompt_contexts!
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the legacy mono-duel engine is intentionally removed"
  end

  private

    def create_duel_invitations!
      create_table :duel_invitations do |t|
        t.references :challenger_person, null: false, foreign_key: { to_table: :people }
        t.references :recipient_person, foreign_key: { to_table: :people }
        t.references :challenger_run, foreign_key: { to_table: :quiz_runs }
        t.integer :challenger_score
        t.references :claimed_by_person, foreign_key: { to_table: :people }
        t.references :street_duel, foreign_key: true
        t.references :rematch_of_duel, foreign_key: { to_table: :street_duels }
        t.bigint :acquisition_parent_invitation_id
        t.string :token_digest, null: false
        t.string :legacy_token_digest
        t.string :status, null: false, default: "open"
        t.string :source
        t.string :channel
        t.datetime :share_handoff_at
        t.datetime :human_opened_at
        t.datetime :delivered_at
        t.datetime :seen_at
        t.datetime :claimed_at
        t.datetime :declined_at
        t.datetime :revoked_at
        t.datetime :expires_at, null: false
        t.jsonb :metadata, null: false, default: {}
        t.timestamps
      end

      add_foreign_key :duel_invitations, :duel_invitations,
        column: :acquisition_parent_invitation_id
      add_index :duel_invitations, :token_digest, unique: true
      add_index :duel_invitations, :legacy_token_digest, unique: true,
        where: "legacy_token_digest IS NOT NULL"
      add_index :duel_invitations, [ :recipient_person_id, :status, :updated_at ],
        name: "index_duel_invitations_on_recipient_inbox"
      add_index :duel_invitations, [ :challenger_person_id, :status, :updated_at ],
        name: "index_duel_invitations_on_challenger_outbox"
      add_check_constraint :duel_invitations,
        "status IN ('open','claimed','declined','expired','revoked')",
        name: "duel_invitations_status_check"
      add_check_constraint :duel_invitations,
        "recipient_person_id IS NULL OR recipient_person_id <> challenger_person_id",
        name: "duel_invitations_distinct_people_check"
    end

    def expand_duels!
      change_table :street_duels, bulk: true do |t|
        t.references :origin_invitation, foreign_key: { to_table: :duel_invitations }
        t.bigint :pair_low_person_id
        t.bigint :pair_high_person_id
        t.datetime :challenger_result_seen_at
        t.datetime :opponent_result_seen_at
        t.datetime :resolved_notified_at
      end
    end

    def migrate_legacy_duels!
      rows = connection.select_all("SELECT * FROM street_duels ORDER BY id").to_a
      keep_ids = rows.select { |row| keep_as_active_duel?(row) }.pluck("id").to_set
      rows.each do |row|
        keep_duel = keep_ids.include?(row["id"])
        invitation_id = insert_invitation!(row, keep_duel:, keep_ids:)

        execute <<~SQL.squish
          UPDATE viral_events
          SET duel_invitation_id = #{invitation_id}#{", street_duel_id = NULL" unless keep_duel}
          WHERE street_duel_id = #{connection.quote(row.fetch("id"))}
        SQL
        execute <<~SQL.squish
          UPDATE notification_deliveries
          SET subject_type = 'DuelInvitation', subject_id = #{invitation_id}, updated_at = CURRENT_TIMESTAMP
          WHERE subject_type = 'StreetDuel'
            AND subject_id = #{connection.quote(row.fetch("id"))}
            AND kind IN ('duel_invitation', 'duel_reminder')
        SQL

        if keep_duel
          execute <<~SQL.squish
            UPDATE street_duels
            SET origin_invitation_id = #{invitation_id}
            WHERE id = #{connection.quote(row.fetch("id"))}
          SQL
        else
          execute <<~SQL.squish
            UPDATE quiz_runs
            SET street_duel_id = NULL, updated_at = CURRENT_TIMESTAMP
            WHERE street_duel_id = #{connection.quote(row.fetch("id"))}
          SQL
          execute <<~SQL.squish
            UPDATE notification_deliveries
            SET subject_type = NULL, subject_id = NULL, status = 'cancelled',
                cancelled_at = COALESCE(cancelled_at, CURRENT_TIMESTAMP), updated_at = CURRENT_TIMESTAMP
            WHERE subject_type = 'StreetDuel' AND subject_id = #{connection.quote(row.fetch("id"))}
          SQL
          execute "UPDATE street_duels SET rematch_of_id = NULL WHERE rematch_of_id = #{connection.quote(row.fetch("id"))}"
          execute "DELETE FROM street_duels WHERE id = #{connection.quote(row.fetch("id"))}"
        end
      end

      execute <<~SQL
        UPDATE street_duels
        SET status = CASE
          WHEN expires_at <= CURRENT_TIMESTAMP AND status <> 'resolved' THEN 'expired'
          WHEN status IN ('challenger_done', 'opponent_done') THEN 'one_scored'
          WHEN status = 'resolved' THEN 'resolved'
          WHEN status = 'archived' THEN 'archived'
          ELSE 'active'
        END,
        accepted_at = COALESCE(accepted_at, created_at),
        pair_low_person_id = LEAST(challenger_person_id, opponent_person_id),
        pair_high_person_id = GREATEST(challenger_person_id, opponent_person_id)
      SQL

      execute <<~SQL
        WITH duplicates AS (
          SELECT id,
                 ROW_NUMBER() OVER (
                   PARTITION BY pair_low_person_id, pair_high_person_id
                   ORDER BY COALESCE(accepted_at, created_at) DESC, id DESC
                 ) AS position
          FROM street_duels
          WHERE status IN ('active', 'one_scored')
        )
        UPDATE street_duels
        SET status = 'archived', updated_at = CURRENT_TIMESTAMP
        FROM duplicates
        WHERE street_duels.id = duplicates.id AND duplicates.position > 1
      SQL
    end

    def keep_as_active_duel?(row)
      return false if row["opponent_person_id"].blank?
      return false if row["status"].in?(%w[declined archived])

      row["status"] == "resolved" || row["accepted_at"].present? || row["opponent_run_id"].present?
    end

    def insert_invitation!(row, keep_duel:, keep_ids:)
      old_token = row.fetch("token")
      status = invitation_status(row, keep_duel:)
      claimed_at = keep_duel ? (row["accepted_at"] || row["updated_at"]) : nil
      declined_at = status == "declined" ? row["updated_at"] : nil
      revoked_at = status == "revoked" ? row["updated_at"] : nil
      claimed_by_id = keep_duel ? row["opponent_person_id"] : nil
      street_duel_id = keep_duel ? row["id"] : nil
      values = {
        challenger_person_id: row["challenger_person_id"],
        recipient_person_id: row["opponent_person_id"],
        challenger_run_id: row["challenger_run_id"],
        challenger_score: row["challenger_score"],
        claimed_by_person_id: claimed_by_id,
        street_duel_id:,
        rematch_of_duel_id: (row["rematch_of_id"] if keep_ids.include?(row["rematch_of_id"])),
        token_digest: Digest::SHA256.hexdigest("campus:migrated:#{old_token}"),
        legacy_token_digest: Digest::SHA256.hexdigest(old_token),
        status:,
        source: "legacy_cutover",
        channel: row["opponent_person_id"].present? ? "noche" : "link",
        delivered_at: row["delivered_at"],
        seen_at: row["seen_at"],
        claimed_at:,
        declined_at:,
        revoked_at:,
        expires_at: row["expires_at"],
        created_at: row["created_at"],
        updated_at: row["updated_at"]
      }
      columns = values.keys.join(", ")
      quoted = values.values.map { |value| connection.quote(value) }.join(", ")
      connection.select_value(<<~SQL.squish).to_i
        INSERT INTO duel_invitations (#{columns})
        VALUES (#{quoted})
        RETURNING id
      SQL
    end

    def invitation_status(row, keep_duel:)
      return "claimed" if keep_duel
      return "declined" if row["status"] == "declined"
      return "revoked" if row["status"] == "archived"
      return "expired" if row["expires_at"] && row["expires_at"] <= Time.current

      "open"
    end

    def contract_duels!
      change_column_default :street_duels, :status, from: "pending", to: "active"
      change_column_null :street_duels, :opponent_person_id, false
      change_column_null :street_duels, :pair_low_person_id, false
      change_column_null :street_duels, :pair_high_person_id, false
      change_column_null :street_duels, :origin_invitation_id, false

      add_index :street_duels, [ :pair_low_person_id, :pair_high_person_id ],
        unique: true,
        where: "status IN ('active','one_scored')",
        name: "index_street_duels_on_unique_active_pair"
      add_check_constraint :street_duels,
        "status IN ('active','one_scored','resolved','expired','archived')",
        name: "street_duels_status_check"
      add_check_constraint :street_duels,
        "challenger_person_id <> opponent_person_id",
        name: "street_duels_distinct_people_check"
      add_check_constraint :street_duels,
        "pair_low_person_id < pair_high_person_id",
        name: "street_duels_ordered_pair_check"

      remove_index :quiz_runs, name: "index_quiz_runs_on_finished_adventure_scores", if_exists: true
      remove_reference :quiz_runs, :street_duel, foreign_key: true
      add_index :quiz_runs, [ :person_id, :pack_id, :score ],
        order: { score: :desc },
        where: "status = 'finished'",
        name: "index_quiz_runs_on_finished_scores"

      remove_column :street_duels, :pack_id, :string
      remove_column :street_duels, :token, :string
      remove_column :street_duels, :delivered_at, :datetime
      remove_column :street_duels, :seen_at, :datetime
      remove_column :street_duels, :challenger_delta, :integer
      remove_column :street_duels, :opponent_delta, :integer
      remove_reference :street_duels, :ward, foreign_key: true
      remove_reference :street_duels, :challenger_ward, foreign_key: { to_table: :wards }
      remove_reference :street_duels, :opponent_ward, foreign_key: { to_table: :wards }
      remove_column :street_duels, :stake_unit_id, :string
    end

    def prepare_viral_events!
      add_reference :viral_events, :duel_invitation, foreign_key: true
      add_column :viral_events, :event_key, :string
      add_index :viral_events, :event_key, unique: true, where: "event_key IS NOT NULL"
    end

    def finalize_viral_events!
      execute <<~SQL
        UPDATE viral_events
        SET duel_invitation_id = duel_invitations.id
        FROM duel_invitations
        WHERE duel_invitations.street_duel_id = viral_events.street_duel_id
      SQL
      execute <<~SQL
        UPDATE viral_events
        SET name = CASE name
          WHEN 'invite_share_completed' THEN 'invite_share_handoff'
          WHEN 'invite_link_opened' THEN 'invite_link_rendered'
          WHEN 'invitee_registered' THEN 'invitee_profile_created'
          WHEN 'challenge_started' THEN 'duel_activated'
          WHEN 'challenge_completed' THEN 'duel_resolved'
          WHEN 'rematch_started' THEN 'duel_rematch_started'
          ELSE name
        END
      SQL
    end

    def migrate_notification_prompt_contexts!
      execute <<~SQL
        UPDATE notification_prompt_states
        SET offer_context = CASE offer_context
          WHEN 'challenge_sent' THEN 'duel_invitation_sent'
          WHEN 'challenge_inbox' THEN 'duel_campus'
          WHEN 'challenge_result' THEN 'duel_result'
          ELSE offer_context
        END,
        updated_at = CURRENT_TIMESTAMP
        WHERE offer_context IN ('challenge_sent', 'challenge_inbox', 'challenge_result')
      SQL
    end
end
