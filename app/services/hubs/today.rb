module Hubs
  # Chooses one real reason to return today from presentation data already
  # loaded by Hubs::Screen. This service does not query, translate or invent
  # copy: each field comes from the selected source and the view owns generic
  # labels. When nothing has been scheduled, the fallback stays deliberately
  # sparse instead of duplicating the Hero as fabricated news. Its local date
  # is supplied by the browser, where "today" can be stated truthfully.
  class Today
    Item = Struct.new(
      :kind, :state, :eyebrow, :title, :body, :setup, :question,
      :cite, :meta, :artwork, :path, :method, :external,
      :scheduled_on, :starts_on, :ends_on, :starts_at,
      :theme_mode, :theme_atmosphere, :action_label, :source_id,
      keyword_init: true
    )

    LIVE_STATES = %i[playing imminent].freeze

    def self.call(live:, study:, rama_events:, locale: I18n.locale)
      new(live:, study:, rama_events:, locale:).call
    end

    def initialize(live:, study:, rama_events:, locale:)
      @live = live
      @study = study
      @rama_events = Array(rama_events)
      @locale = Locale.i18n(locale)
      @routes = Rails.application.routes.url_helpers
    end

    def call
      live_item || daily_discovery_item || expedition_item || weekly_item || rama_event_item || fallback_item
    end

    private

      def live_item
        return unless @live && LIVE_STATES.include?(@live.state&.to_sym)

        Item.new(
          kind: @live.state.to_sym == :playing ? :live : :live_upcoming,
          state: @live.state.to_sym,
          title: @live.title,
          artwork: @live.still,
          path: @live.join_path.presence || @live.program_path,
          method: :get,
          starts_at: @live.starts_at,
          theme_mode: @live.theme_mode,
          theme_atmosphere: @live.theme_atmosphere
        )
      end

      def daily_discovery_item
        discovery = @study&.daily_discovery
        return unless discovery

        cite = daily_discovery_cite(discovery)
        return unless cite

        Item.new(
          kind: :daily_discovery,
          state: discovery.kind.to_sym,
          eyebrow: discovery.eyebrow,
          title: discovery.title,
          setup: discovery.setup,
          question: discovery.question,
          cite:,
          artwork: discovery.artwork_key,
          path: daily_discovery_path(discovery, cite:),
          method: :get,
          scheduled_on: discovery.scheduled_on,
          starts_on: discovery.scheduled_on,
          ends_on: discovery.scheduled_on,
          action_label: discovery.cta_label,
          source_id: discovery.reference
        )
      end

      def daily_discovery_cite(discovery)
        reference = Scriptures::Reference.from_study(
          study: discovery.reference,
          locale: @locale,
          verse: 1
        )
        return unless reference
        return "#{reference.book_label} #{reference.chapter}" unless discovery.kind == "contemplation"

        references = discovery.references.filter_map do |study|
          Scriptures::Reference.from_study(study:, locale: @locale, verse: 1)
        end
        return "#{reference.book_label} #{reference.chapter}" unless references.size == discovery.references.size
        return "#{reference.book_label} #{reference.chapter}" unless references.map(&:base_study).uniq.one?

        first, last = references.minmax_by(&:chapter)
        chapters = first.chapter == last.chapter ? first.chapter.to_s : "#{first.chapter}–#{last.chapter}"
        "#{first.book_label} #{chapters}"
      end

      # Keep this in lockstep with ScriptureLibraries::Screen: a discovery
      # opens its exact chapter; a contemplation returns to the merged weekly
      # Library surface instead of pretending to be one isolated passage.
      def daily_discovery_path(discovery, cite:)
        if discovery.kind == "contemplation"
          @routes.scripture_library_path(
            section: :weekly,
            locale: @locale,
            unit: @study.week.id,
            anchor: "cette-semaine"
          )
        else
          @routes.scripture_path(discovery.reference, cite:, locale: @locale)
        end
      end

      def expedition_item
        expedition = @study&.expedition
        return unless expedition&.state&.to_sym == :active

        pack = expedition.packs.find { |candidate| candidate.state&.to_sym != :finished }
        return unless pack

        Item.new(
          kind: :expedition,
          state: pack.state.to_sym,
          title: pack.title,
          body: pack.hook.presence || pack.lede,
          cite: pack.kicker,
          meta: expedition.title,
          artwork: pack.artwork,
          path: @routes.street_map_path(view: "expeditions", expedition: expedition.study_unit_id),
          method: :get,
          starts_on: expedition.starts_on,
          ends_on: expedition.ends_on
        )
      end

      def weekly_item
        return unless @study&.week

        reading = Array(@study.weekly_reading_cards).find { |card| card.status&.to_sym != :completed }
        return weekly_reading_item(reading) if reading

        weekly_program_item
      end

      def weekly_reading_item(reading)
        Item.new(
          kind: :weekly_reading,
          state: reading.status.to_sym,
          title: reading.title,
          cite: reading.cite,
          artwork: reading.artwork,
          path: @routes.scripture_path(
            reading.study,
            cite: reading.cite,
            study_unit_id: reading.study_unit_id,
            locale: @locale
          ),
          method: :get,
          starts_on: @study.week.starts_on,
          ends_on: @study.week.ends_on,
          source_id: reading.study
        )
      end

      def weekly_program_item
        week = @study.week
        Item.new(
          kind: :weekly_program,
          state: week.status.to_sym,
          title: week.theme(@locale),
          meta: week.display_period(@locale),
          artwork: Array(@study.weekly_reading_cards).first&.artwork,
          path: @routes.scripture_library_path(
            section: :weekly,
            locale: @locale,
            unit: week.id,
            anchor: "cette-semaine"
          ),
          method: :get,
          starts_on: week.starts_on,
          ends_on: week.ends_on
        )
      end

      def rama_event_item
        event = @rama_events
          .select { |candidate| candidate.state&.to_sym == :published }
          .min_by { |candidate| [ candidate.starts_at || Time.utc(9999), candidate.event_id.to_i ] }
        return unless event

        Item.new(
          kind: :rama_event,
          state: event.state.to_sym,
          title: event.title,
          body: event.summary,
          meta: event.location_label,
          artwork: event.still,
          path: event.path,
          method: :get,
          external: event.external,
          starts_at: event.starts_at,
          source_id: event.event_id
        )
      end

      def fallback_item
        Item.new(
          kind: :fallback,
          state: :available
        )
      end
  end
end
