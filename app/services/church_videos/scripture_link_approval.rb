module ChurchVideos
  class ScriptureLinkApproval
    Error = Class.new(StandardError)

    def self.call(reference:, locale:, youtube_video_id:, editorial_reason:, reviewed_by:, position: 0, themes: [], at: Time.current, **catalog_options)
      candidates = Catalog.scripture_candidates(reference:, locale:, themes:, **catalog_options)
      raise Error, "official candidate search is unavailable (#{candidates.error})" unless candidates.available?

      candidate = candidates.candidates.find { |item| item.id == youtube_video_id.to_s }
      raise Error, "video is not a verified candidate from the configured official channel" unless candidate

      ScriptureVideoLink.transaction do
        link = ScriptureVideoLink.find_or_initialize_by(
          reference: candidates.reference,
          locale: candidates.locale,
          youtube_video_id: candidate.id
        )
        link.assign_attributes(
          channel_id: candidate.channel_id,
          source_url: "https://www.youtube.com/watch?v=#{candidate.id}",
          editorial_reason: editorial_reason.to_s.squish,
          reviewed_by: reviewed_by.to_s.squish,
          position:,
          status: "published",
          verified_at: at,
          published_at: at
        )
        link.save!
        link
      end
    end
  end
end
