require "test_helper"

module ScriptureCircles
  class LibraryHighlightsTest < ActiveSupport::TestCase
    setup do
      @ward = wards(:demo)
      @ward.update!(scripture_circle_mode: "active", time_zone: "Europe/Madrid")
      @viewer = people(:pili)
      @author = people(:carmen_garcia)
      @other = people(:carmen_lopez)
      @at = Time.utc(2044, 8, 30, 22, 30) # 31 August in Madrid
    end

    test "returns at most two recent thoughts from today's weekly references" do
      older = create_root(
        person: @author,
        reference: "ot/ps/102",
        body: "Pourquoi cette prière commence-t-elle dans l'épuisement ?",
        at: Time.utc(2044, 8, 30, 23, 0)
      )
      middle = create_root(
        person: @other,
        reference: "ot/ps/110",
        body: "Je n'avais jamais remarqué Melchisédek ici.",
        kind: "reflection",
        at: Time.utc(2044, 8, 31, 0, 0)
      )
      newest = create_root(
        person: @author,
        reference: "ot/ps/119",
        body: "Pourquoi le dernier verset demande-t-il encore d'être cherché ?",
        at: Time.utc(2044, 8, 31, 1, 0)
      )
      create_reply(parent: newest, person: @viewer, body: "Je me pose la même question.")
      create_root(
        person: @author,
        reference: "nt/john/3",
        body: "Cette autre lecture n'appartient pas au corpus de la semaine.",
        at: Time.utc(2044, 8, 31, 2, 0)
      )
      create_root(
        person: @author,
        reference: "ot/ps/102",
        body: "Cette pensée date de la veille locale.",
        at: Time.utc(2044, 8, 30, 20, 0)
      )

      highlights = LibraryHighlights.call(
        person: @viewer,
        locale: :fr,
        references: %w[ot/ps/102 ot/ps/110 ot/ps/119],
        at: @at
      )

      assert_equal [ newest.id, middle.id ], highlights.map(&:id)
      assert_equal 2, highlights.size
      assert_equal 1, highlights.first.reply_count
      assert_equal "Psaumes 119", highlights.first.citation
      assert_equal newest.body, highlights.first.body
      assert_equal Rails.application.routes.url_helpers.scripture_circle_path(
        locale: :fr,
        conversation: newest.id
      ), highlights.first.path
      assert_equal "/escrituras/ot/ps/119", URI.parse(highlights.first.reader_path).path
      refute_includes highlights.map(&:id), older.id
      assert highlights.frozen?
      assert highlights.all? { |highlight| !highlight.respond_to?(:person) }
    end

    test "keeps anonymous authors anonymous and redacts former members" do
      anonymous = create_root(
        person: @author,
        reference: "ot/ps/102",
        body: "Puis-je demander cela sans afficher mon nom ?",
        author_visibility: "anonymous_to_ward",
        at: Time.utc(2044, 8, 31, 1, 0)
      )
      former = create_root(
        person: @other,
        reference: "ot/ps/110",
        body: "Cette réflexion reste après mon départ.",
        kind: "reflection",
        at: Time.utc(2044, 8, 31, 0, 0)
      )
      @other.update!(ward: extra_ward)

      highlights = LibraryHighlights.call(
        person: @viewer,
        locale: :fr,
        references: %w[ot/ps/102 ot/ps/110],
        at: @at
      ).index_by(&:id)

      anonymous_highlight = highlights.fetch(anonymous.id)
      assert_predicate anonymous_highlight, :anonymous?
      assert_nil anonymous_highlight.avatar_key
      assert_equal I18n.t("scripture_reader.circle.anonymous", locale: :fr), anonymous_highlight.author_name
      refute_equal @author.display_name, anonymous_highlight.author_name

      former_highlight = highlights.fetch(former.id)
      assert_not former_highlight.anonymous?
      assert_nil former_highlight.avatar_key
      assert_equal I18n.t("scripture_reader.circle.former_member", locale: :fr), former_highlight.author_name
      refute_equal @other.display_name, former_highlight.author_name
    end

    test "omits the section when access or references are absent" do
      assert_empty LibraryHighlights.call(person: nil, locale: :fr, references: [ "ot/ps/102" ], at: @at)
      assert_empty LibraryHighlights.call(person: @viewer, locale: :fr, references: [], at: @at)

      @ward.update!(scripture_circle_mode: "disabled")
      assert_empty LibraryHighlights.call(
        person: @viewer,
        locale: :fr,
        references: [ "ot/ps/102" ],
        at: @at
      )
    end

    private

      def create_root(person:, reference:, body:, kind: "question", author_visibility: "named", at:)
        thread = @ward.scripture_circle_threads.find_or_create_by!(reference:)
        travel_to(at) do
          thread.scripture_circle_posts.create!(
            ward: @ward,
            person:,
            kind:,
            locale: "fr",
            body:,
            author_visibility:
          )
        end
      end

      def create_reply(parent:, person:, body:)
        travel_to(parent.created_at + 10.minutes) do
          parent.scripture_circle_thread.scripture_circle_posts.create!(
            ward: @ward,
            person:,
            kind: "reply",
            parent:,
            locale: "fr",
            body:
          )
        end
      end

      def extra_ward
        Ward.create!(
          name: "Ancienne rama #{SecureRandom.hex(3)}",
          code: "OLD#{SecureRandom.hex(3).upcase}",
          admin_token_digest: GameSession.digest_token(SecureRandom.hex(12)),
          emblem: Team::EMBLEMS.keys.first,
          time_zone: "Europe/Madrid",
          scripture_circle_mode: "active"
        )
      end
  end
end
