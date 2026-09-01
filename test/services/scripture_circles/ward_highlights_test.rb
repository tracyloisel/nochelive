require "test_helper"

module ScriptureCircles
  class WardHighlightsTest < ActiveSupport::TestCase
    setup do
      @ward = wards(:demo)
      @ward.update!(scripture_circle_mode: "active", time_zone: "Europe/Madrid")
      @viewer = people(:pili)
      @author = people(:carmen_garcia)
      @at = Time.utc(2044, 8, 31, 12)
    end

    test "returns the two most recently active weekly conversations" do
      older = create_root(reference: "ot/ps/102", body: "Une ancienne question", at: @at - 2.days)
      recent = create_root(reference: "ot/ps/110", body: "Une question recente", at: @at - 1.day)
      newest = create_root(reference: "ot/ps/119", body: "La derniere question", at: @at - 2.hours)
      create_reply(parent: older, body: "Une reponse de ce matin", at: @at - 1.hour)

      highlights = WardHighlights.call(
        ward: @ward,
        person: @viewer,
        locale: :fr,
        references: %w[ot/ps/102 ot/ps/110 ot/ps/119],
        at: @at
      )

      assert_equal [ older.id, newest.id ], highlights.map(&:id)
      assert_equal 1, highlights.first.reply_count
      assert_equal "Psaumes 102", highlights.first.citation
      assert highlights.frozen?
    end

    test "uses the latest activity and excludes conversations outside seven local days" do
      kept = create_root(reference: "ot/ps/102", body: "Question ravivee", at: @at - 12.days)
      create_reply(parent: kept, body: "Reponse recente", at: @at - 6.days)
      excluded = create_root(reference: "ot/ps/110", body: "Conversation trop ancienne", at: @at - 8.days)

      highlights = WardHighlights.call(
        ward: @ward,
        person: @viewer,
        locale: :fr,
        references: %w[ot/ps/102 ot/ps/110],
        at: @at
      )

      assert_equal [ kept.id ], highlights.map(&:id)
      refute_includes highlights.map(&:id), excluded.id
    end

    test "never exposes another ward or a disabled circle" do
      create_root(reference: "ot/ps/102", body: "Question privee", at: @at)
      other = extra_ward

      assert_empty WardHighlights.call(
        ward: other,
        person: @viewer,
        locale: :fr,
        references: [ "ot/ps/102" ],
        at: @at
      )

      @ward.update!(scripture_circle_mode: "disabled")
      assert_empty WardHighlights.call(
        ward: @ward,
        person: @viewer,
        locale: :fr,
        references: [ "ot/ps/102" ],
        at: @at
      )
    end

    private

      def create_root(reference:, body:, at:)
        thread = @ward.scripture_circle_threads.find_or_create_by!(reference:)
        travel_to(at) do
          thread.scripture_circle_posts.create!(
            ward: @ward,
            person: @author,
            kind: "question",
            locale: "fr",
            body:
          )
        end
      end

      def create_reply(parent:, body:, at:)
        travel_to(at) do
          parent.scripture_circle_thread.scripture_circle_posts.create!(
            ward: @ward,
            person: @viewer,
            kind: "reply",
            parent:,
            locale: "fr",
            body:
          )
        end
      end

      def extra_ward
        Ward.create!(
          name: "Autre rama #{SecureRandom.hex(3)}",
          code: "EXT#{SecureRandom.hex(3).upcase}",
          admin_token_digest: GameSession.digest_token(SecureRandom.hex(12)),
          emblem: Team::EMBLEMS.keys.first,
          time_zone: "Europe/Madrid",
          scripture_circle_mode: "active"
        )
      end
  end
end
