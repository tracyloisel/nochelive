namespace :noche do
  desc "Wipe nights and quiz runs, then seed a playable DEMO"
  task reseed: :environment do
    night = Nights::Reseed.call
    abort "DEMO night missing after reseed" unless night&.live?

    puts "DEMO #{night.status} · #{night.theme_title}"
  end

  desc "Import listed wards from the Meetinghouse Locator or FILE= JSON"
  task import_wards: :environment do
    load Rails.root.join("script/import_meetinghouses.rb")
  end

  desc "Seed every Scripture Campus state locally (PERSON_ID=21 or NAME='Test Feu', PORT=3091)"
  task duel_campus_demo: :environment do
    load Rails.root.join("db/seeds/duel_campus_demo.rb")
  end

  desc "Seed the Scripture Reader circle locally (PERSON_ID=21 or NAME='Tracy', PORT=3091)"
  task scripture_circle_demo: :environment do
    load Rails.root.join("db/seeds/scripture_circle_demo.rb")
  end

  desc "Find editorial video candidates from the configured official Church channel (REFERENCE=ot/ps/52 LOCALE=fr THEMES=confiance,verite)"
  task scripture_video_candidates: :environment do
    reference = ENV.fetch("REFERENCE")
    locale = ENV.fetch("LOCALE", I18n.default_locale)
    themes = ENV.fetch("THEMES", "").split(",")
    result = ChurchVideos::Catalog.scripture_candidates(reference:, locale:, themes:)
    abort "candidate search unavailable: #{result.error}" unless result.available?

    puts "#{result.reference} · #{result.locale} · #{result.channel.title} (#{result.channel.id})"
    puts "query=#{result.query.inspect} candidates=#{result.candidates.size}"
    result.candidates.each do |candidate|
      puts "#{candidate.id}\tscore=#{candidate.score}\t#{candidate.title}"
    end
  end

  desc "Publish one manually reviewed official video association (REFERENCE=... LOCALE=... VIDEO_ID=... REASON=... REVIEWER=...)"
  task approve_scripture_video: :environment do
    link = ChurchVideos::ScriptureLinkApproval.call(
      reference: ENV.fetch("REFERENCE"),
      locale: ENV.fetch("LOCALE", I18n.default_locale),
      youtube_video_id: ENV.fetch("VIDEO_ID"),
      editorial_reason: ENV.fetch("REASON"),
      reviewed_by: ENV.fetch("REVIEWER"),
      themes: ENV.fetch("THEMES", "").split(",")
    )
    puts "published scripture video link ##{link.id} · #{link.reference} · #{link.youtube_video_id}"
  end

  desc "Backfill Church Maps payload and stake id on stored ramas (FORCE=1 UNIT=333239)"
  task backfill_locator: :environment do
    stats = Wards::BackfillLocator.call(
      force: ENV["FORCE"].present?,
      church_unit_id: ENV["UNIT"].presence
    )
    puts "locator backfill · candidates=#{stats.candidates} updated=#{stats.updated} missing=#{stats.missing} skipped=#{stats.skipped}"
  end
end

namespace :media do
  desc "Build deterministic responsive AVIF/WebP/JPEG derivatives and manifest"
  task build_responsive: :environment do
    require Rails.root.join("lib/media_pipeline")
    manifest = MediaPipeline.new.call
    assets = manifest.fetch("assets")
    variants = assets.values.sum do |asset|
      asset.fetch("renditions").values.sum { |rendition| rendition.fetch("variants").values.sum(&:size) }
    end
    puts "responsive media · assets=#{assets.size} variants=#{variants}"
  end
end

namespace :come_follow_me do
  desc "Import an official annual program URL and attach Noche editorial quizzes (URL=... DRY_RUN=1)"
  task import: :environment do
    url = ENV.fetch("URL")
    result = Studies::ProgramImporter.call(url:, dry_run: ENV["DRY_RUN"].present?)
    puts "#{result.program.title} · created=#{result.created} updated=#{result.updated} unchanged=#{result.unchanged}"
    next if ENV["DRY_RUN"].present?

    versions = Studies::EditorialImporter.call(program: result.program)
    puts "editorial quizzes=#{versions.size} · #{versions.map { |version| "#{version.study_unit.slug}@v#{version.version}:#{version.status}" }.join(', ')}"
  end

  desc "Publish a reviewed annual program and its review-ready quiz versions (YEAR=2026)"
  task publish: :environment do
    year = ENV.fetch("YEAR", Date.current.year).to_i
    program = StudyProgram.find_by!(year:, locale: "fr")
    versions = program.study_units.flat_map { |unit| unit.study_quiz_versions.where(status: "needs_review") }
    abort "No review-ready quizzes for #{year}" if versions.empty?

    StudyQuizVersion.transaction do
      versions.each { |version| version.update!(status: "published", published_at: Time.current) }
      program.update!(status: "published")
    end
    puts "published #{program.slug} · quizzes=#{versions.size}"
  end
end
