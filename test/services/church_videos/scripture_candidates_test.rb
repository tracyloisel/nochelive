require "test_helper"

class ChurchVideos::ScriptureCandidatesTest < ActiveSupport::TestCase
  setup do
    ChurchVideos::Catalog.forced_result = catalog_result
  end

  teardown do
    ChurchVideos::Catalog.forced_result = nil
  end

  test "returns ranked candidates only from the configured official channel" do
    result = ChurchVideos::Catalog.scripture_candidates(
      reference: "ot/ps/52", locale: "fr", themes: %w[confiance vérité]
    )

    assert result.available?
    assert_equal "UC3CbfUXOgoOsD7srESW98mA", result.channel.id
    assert_equal %w[trustTruth1 calmVideo02], result.candidates.map(&:id)
    assert_operator result.candidates.first.score, :>, result.candidates.last.score
    assert_includes result.query, "Psaumes 52"
  end

  test "fails closed for a channel that is not configured for the locale" do
    ChurchVideos::Catalog.forced_result = catalog_result(channel_id: "UC0000000000000000000000")

    result = ChurchVideos::Catalog.scripture_candidates(reference: "ot/ps/52", locale: "fr")

    refute result.available?
    assert_equal :untrusted_channel, result.error
    assert_empty result.candidates
  end

  test "manual approval publishes verified metadata and rejects an absent candidate" do
    at = Time.zone.parse("2026-08-30 12:00:00")
    link = ChurchVideos::ScriptureLinkApproval.call(
      reference: "ot/ps/52",
      locale: "fr",
      youtube_video_id: "trustTruth1",
      editorial_reason: "Choisir la confiance quand les paroles blessent",
      reviewed_by: "Équipe éditoriale test",
      at:
    )

    assert link.published?
    assert_equal at, link.verified_at
    assert_equal at, link.published_at
    assert_equal "https://www.youtube.com/watch?v=trustTruth1", link.source_url
    assert_includes ScriptureVideoLink.published, link

    assert_raises ChurchVideos::ScriptureLinkApproval::Error do
      ChurchVideos::ScriptureLinkApproval.call(
        reference: "ot/ps/52", locale: "fr", youtube_video_id: "unknown0000",
        editorial_reason: "Non relu", reviewed_by: "Test"
      )
    end
  end

  test "model rejects an association from a foreign channel" do
    link = ScriptureVideoLink.new(
      reference: "ot/ps/52", locale: "fr", youtube_video_id: "trustTruth1",
      channel_id: "UC0000000000000000000000", editorial_reason: "Lien étranger",
      status: "draft", position: 0
    )

    refute link.valid?
    assert_includes link.errors.details[:channel_id].map { |detail| detail[:error] }, :invalid
  end

  private

    def catalog_result(channel_id: "UC3CbfUXOgoOsD7srESW98mA")
      ChurchVideos::Catalog::Result.new(
        channel: ChurchVideos::Catalog::Channel.new(
          id: channel_id, title: "Église de Jésus-Christ", description: "Canal officiel",
          uploads_playlist_id: "UU-official", public_url: "https://www.youtube.com/channel/#{channel_id}"
        ),
        playlists: [], active_playlist: nil, query: "Psaumes 52", next_page_token: nil,
        previous_page_token: nil, error: nil,
        videos: [
          ChurchVideos::Catalog::Video.new(
            id: "calmVideo02", title: "Une parole paisible", description: "Écouter",
            published_at: Time.zone.parse("2026-08-01"), duration_seconds: 120, made_for_kids: false
          ),
          ChurchVideos::Catalog::Video.new(
            id: "trustTruth1", title: "Confiance et vérité", description: "Psaumes et paroles",
            published_at: Time.zone.parse("2026-08-02"), duration_seconds: 180, made_for_kids: false
          )
        ]
      )
    end
end
