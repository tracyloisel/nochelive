module Notifications
  class VerseCatalog
    Entry = Data.define(:id, :study, :verse, :theme) do
      def reference(locale)
        Scriptures::Reference.from_study(study:, locale: Locale.i18n(locale), verse:)
      end

      def destination(locale)
        ref = reference(locale)
        Rails.application.routes.url_helpers.scripture_passage_path(
          **Scriptures::Reference.passage_path_options(ref, ref.locale)
        )
      end

      def citation(locale)
        reference(locale).citation
      end
    end

    def self.for(date)
      entries.fetch(date.yday % entries.size)
    end

    def self.entries
      @entries ||= YAML.safe_load_file(Rails.root.join("config/notifications/verses.yml"))
        .fetch("entries")
        .map { |row| Entry.new(**row.symbolize_keys) }
    end
  end
end
