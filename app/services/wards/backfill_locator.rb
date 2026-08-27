module Wards
  class BackfillLocator
    BATCH = 20
    PAUSE = 0.2
    Result = Struct.new(:candidates, :updated, :missing, :skipped, keyword_init: true)

    def self.call(force: false, church_unit_id: nil)
      new(force:, church_unit_id:).call
    end

    def initialize(force: false, church_unit_id: nil)
      @force = force
      @church_unit_id = church_unit_id.to_s.sub(/\AWARD:/i, "").strip.presence
    end

    def call
      updated = 0
      missing = 0
      skipped = 0
      candidates = scope.count

      scope.in_batches(of: BATCH) do |relation|
        wards = relation.to_a
        rows = QueryLocator.details_for(church_unit_ids: wards.map(&:church_unit_id))
        by_id = rows.index_by { |row| row[:church_unit_id].to_s }
        attrs_list = wards.filter_map do |ward|
          attrs = by_id[ward.church_unit_id.to_s]
          if attrs.blank?
            missing += 1
            nil
          else
            attrs
          end
        end
        if attrs_list.any?
          stats = SyncDirectory.call(rows: attrs_list)
          updated += stats[:updated]
          skipped += stats[:skipped]
        end
        sleep PAUSE unless Rails.env.test?
      end

      Result.new(candidates:, updated:, missing:, skipped:)
    end

    private

      def scope
        rel = Ward.where.not(church_unit_id: nil).where.not(church_unit_id: "")
        rel = rel.where(church_unit_id: @church_unit_id) if @church_unit_id
        rel = rel.where(locator_payload: nil) unless @force
        rel
      end
  end
end
