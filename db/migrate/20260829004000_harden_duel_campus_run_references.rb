class HardenDuelCampusRunReferences < ActiveRecord::Migration[8.1]
  REFERENCES = {
    duel_invitations: [ :challenger_run_id ],
    street_duels: [ :challenger_run_id, :opponent_run_id ]
  }.freeze

  def up
    rebuild_foreign_keys(on_delete: :nullify)
  end

  def down
    rebuild_foreign_keys(on_delete: nil)
  end

  private

    def rebuild_foreign_keys(on_delete:)
      REFERENCES.each do |table, columns|
        columns.each do |column|
          remove_foreign_key table, column: column
          options = { column: column }
          options[:on_delete] = on_delete if on_delete
          add_foreign_key table, :quiz_runs, **options
        end
      end
    end
end
