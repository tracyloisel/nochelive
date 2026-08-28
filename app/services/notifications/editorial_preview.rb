module Notifications
  class EditorialPreview
    SAMPLE_VALUES = {
      "reference" => "Jean 3:16",
      "title" => "Marcher avec le Christ",
      "name" => "Carmen",
      "pack" => "Rois et prophètes",
      "time" => "19:30"
    }.freeze

    def self.call(proposal)
      new(proposal).call
    end

    def initialize(proposal)
      @proposal = proposal
    end

    def call
      @proposal.valid?
      raise ActiveRecord::RecordInvalid, @proposal unless @proposal.errors.empty?

      @proposal.proposal_type == "message" ? message_preview : verse_preview
    end

    private

      def message_preview
        kind = @proposal.payload.fetch("notification_kind")
        copies = @proposal.payload.fetch("translations").to_h do |locale, copy|
          values = SAMPLE_VALUES.slice(*NotificationEditorialProposal::PLACEHOLDERS.fetch(kind, []))
          [ locale, {
            title: copy.fetch("title"),
            body: interpolate(copy.fetch("body"), values),
            raw_body: copy.fetch("body"),
            destination_rule: destination_rule(kind),
            sample_destination: sample_destination(kind, locale)
          } ]
        end
        { type: "message", notification_kind: kind, locales: copies }
      end

      def verse_preview
        payload = @proposal.payload
        entry = Notifications::VerseCatalog::Entry.new(
          id: @proposal.editorial_key,
          study: payload.fetch("study"),
          verse: Integer(payload.fetch("verse")),
          theme: payload.fetch("theme")
        )
        locales = NotificationEditorialProposal::LOCALES.to_h do |locale|
          [ locale, { citation: entry.citation(locale), destination: entry.destination(locale) } ]
        end
        {
          type: "verse",
          publish_on: payload.fetch("publish_on"),
          theme: payload.fetch("theme"),
          locales:
        }
      end

      def interpolate(template, values)
        template.gsub(/%\{([a-z_]+)\}/) { values.fetch(Regexp.last_match(1)) }
      end

      def destination_rule(kind)
        case kind
        when "daily_verse" then "exact_scripture_passage"
        when "study_reading" then "current_study_run"
        when "night_tomorrow", "night_starting_soon" then "exact_noche_live_entry"
        else "exact_duel"
        end
      end

      def sample_destination(kind, locale)
        case kind
        when "daily_verse"
          Notifications::VerseCatalog.entries.first.destination(locale)
        when "study_reading" then "/parole/parcours/123"
        when "night_tomorrow", "night_starting_soon" then "/s/DAVID/name"
        else "/desafio/example-token"
        end
      end
  end
end
