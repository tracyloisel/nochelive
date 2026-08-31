module ApplicationHelper
  TIMER_WARN_RATIO = 0.4
  TIMER_HOT_RATIO = 0.2

  def declare_frontend_resources(**attributes)
    manifest = Frontend::ResourceManifest.new(**attributes)
    content_for(:frontend_resource_manifest, manifest.to_json.html_safe)
    nil
  end

  def frontend_resource_manifest_json
    value = if content_for?(:frontend_resource_manifest)
      content_for(:frontend_resource_manifest)
    else
      Frontend::ResourceManifest.shell.to_json
    end
    json_escape(value.to_s).html_safe
  end

  def frontend_audio_enabled?
    manifest = frontend_resource_manifest
    frontend_notification_sfx.present? || content_for?(:frontend_audio) || manifest.audio["unlock"] == true || manifest.audio["cues"].any? || manifest.audio["bed"].present?
  end

  def enable_frontend_audio
    content_for(:frontend_audio, "enabled")
    nil
  end

  def frontend_audio_catalog
    audio = frontend_resource_manifest.audio
    names = [ "tick", frontend_notification_sfx, audio["bed"], *audio["cues"] ].compact.uniq
    Sfx.catalog.slice(*names)
  end

  def frontend_notification_sfx
    "notification_glint" if flash[:notice].present?
  end

  def surface_stylesheet(name)
    content_for(:surface_stylesheets) do
      stylesheet_link_tag(name, "data-turbo-track": "dynamic")
    end
    nil
  end

  FRONTEND_STYLESHEET_ASSETS = {
    "hub" => "surfaces/hub",
    "gameplay" => "surfaces/gameplay",
    "street_play" => "surfaces/street_play",
    "live_play" => "surfaces/live",
    "live_watch" => "surfaces/live",
    "stats" => "surfaces/stats",
    "rama" => "surfaces/rama",
    "ward_profile" => "surfaces/profile",
    "study" => "surfaces/study",
    "library" => "surfaces/library",
    "scripture" => "surfaces/scripture",
    "circle" => "surfaces/circle",
    "church" => "surfaces/church",
    "entry" => "surfaces/entry",
    "profile" => "surfaces/profile",
    "identity" => "surfaces/identity"
  }.freeze

  FRONTEND_CONTROLLER_STYLES = {
    "church_videos" => %w[church],
    "discovery" => %w[church],
    "fichas" => %w[entry profile],
    "identity_transfers" => %w[identity],
    "notification_settings" => %w[profile],
    "pages" => %w[church],
    "players" => %w[live entry],
    "scriptures" => %w[scripture],
    "scripture_libraries" => %w[library],
    "scripture_circles" => %w[circle],
    "scripture_circle_moderation_histories" => %w[scripture],
    "scripture_circle_profile_posts" => %w[profile scripture],
    "searches" => %w[church],
    "street_hub" => %w[hub],
    "street_leaderboards" => %w[stats],
    "street_profiles" => %w[entry profile],
    "street_quiz_histories" => %w[profile],
    "study_communities" => %w[study],
    "study_histories" => %w[study],
    "study_programs" => %w[study],
    "study_runs" => %w[study scripture],
    "study_units" => %w[study scripture],
    "ward_adds" => %w[church],
    "ward_gates" => %w[entry profile],
    "ward_profiles" => %w[profile rama],
    "wards" => %w[entry profile]
  }.freeze

  def frontend_surface_stylesheet_tags
    manifest = frontend_resource_manifest
    assets = manifest.styles.filter_map { |name| FRONTEND_STYLESHEET_ASSETS[name] }
    assets.concat(FRONTEND_CONTROLLER_STYLES.fetch(controller_path, [])) if manifest.context == "shell"
    assets = assets.map { |name| name.include?("/") ? name : "surfaces/#{name}" }

    safe_join(assets.uniq.map do |asset|
      stylesheet_link_tag(asset, "data-turbo-track": "dynamic")
    end)
  end

  def noche_picture(key, role: nil, alt:, class_name: nil, picture_class: nil, loading: "lazy", decoding: "async", fetchpriority: nil, sizes: nil, data: {})
    asset = Frontend::MediaManifest.fetch(key) || Frontend::MediaManifest.fetch_path(key)
    return unless asset
    return if role && asset.fetch("role") != role.to_s

    renditions = asset.fetch("renditions", { "default" => { "media" => nil, "sizes" => asset.fetch("sizes"), "variants" => asset.fetch("variants") } })
    primary = renditions.values.first
    fallback = primary.fetch("variants").fetch("jpeg").last
    sources = renditions.values.flat_map do |rendition|
      %w[avif webp].map do |format|
        variants = rendition.fetch("variants").fetch(format)
        tag.source(
          type: "image/#{format}",
          media: rendition["media"],
          srcset: responsive_srcset(variants),
          sizes: sizes || rendition.fetch("sizes")
        )
      end
    end
    image = image_tag(
      fallback.fetch("src"),
      alt:,
      class: class_name,
      width: fallback.fetch("width"),
      height: fallback.fetch("height"),
      srcset: responsive_srcset(primary.fetch("variants").fetch("jpeg")),
      sizes: sizes || primary.fetch("sizes"),
      loading:,
      decoding:,
      fetchpriority:,
      data: data.merge(media_focus: asset.fetch("focus"))
    )
    wrapper_class = picture_class || (class_name.present? ? "#{class_name}-picture" : nil)
    tag.picture(safe_join([ *sources, image ]), class: wrapper_class)
  end

  def noche_media_picture(source, **attributes)
    picture = noche_picture(source, **attributes)
    return picture if picture

    image_attributes = attributes.slice(:alt, :loading, :decoding, :fetchpriority, :sizes, :data)
    image_attributes[:class] = attributes[:class_name] if attributes[:class_name].present?
    image_tag(media_src(source) || source, **image_attributes)
  end

  def noche_picture_preload(key, role: nil)
    asset = Frontend::MediaManifest.fetch(key) || Frontend::MediaManifest.fetch_path(key)
    return unless asset
    return if role && asset.fetch("role") != role.to_s

    renditions = asset.fetch("renditions", { "default" => { "media" => nil, "sizes" => asset.fetch("sizes"), "variants" => asset.fetch("variants") } })
    safe_join(renditions.values.map do |rendition|
      variants = rendition.fetch("variants").fetch("avif")
      tag.link(
        rel: "preload",
        as: "image",
        type: "image/avif",
        media: rendition["media"],
        href: variants.last.fetch("src"),
        imagesrcset: responsive_srcset(variants),
        imagesizes: rendition.fetch("sizes"),
        fetchpriority: "high"
      )
    end)
  end

  def responsive_srcset(variants)
    variants.map { |variant| "#{variant.fetch('src')} #{variant.fetch('width')}w" }.join(", ")
  end

  def frontend_resource_manifest
    if content_for?(:frontend_resource_manifest)
      Frontend::ResourceManifest.new(**JSON.parse(content_for(:frontend_resource_manifest)).symbolize_keys)
    else
      Frontend::ResourceManifest.shell
    end
  end

  def seo_head_tags
    seo = seo_metadata || {}
    page_title = seo[:title].presence || content_for(:title).presence || "Noche Live"
    tags = [ tag.meta(name: "robots", content: seo[:robots] || "noindex, nofollow") ]

    if seo[:description].present?
      tags << tag.meta(name: "description", content: seo[:description])
      tags << tag.meta(property: "og:description", content: seo[:description])
      tags << tag.meta(name: "twitter:description", content: seo[:description])
    end
    if seo[:canonical].present?
      tags << tag.link(rel: "canonical", href: seo[:canonical])
      tags << tag.meta(property: "og:url", content: seo[:canonical])
    end

    tags << tag.meta(property: "og:type", content: "website")
    tags << tag.meta(property: "og:site_name", content: "Noche Live")
    tags << tag.meta(property: "og:title", content: page_title)
    tags << tag.meta(name: "twitter:card", content: "summary_large_image")
    tags << tag.meta(name: "twitter:title", content: page_title)
    if seo[:image].present?
      tags << tag.meta(property: "og:image", content: seo[:image])
      tags << tag.meta(name: "twitter:image", content: seo[:image])
    end

    seo.fetch(:alternates, {}).each do |locale, url|
      tags << tag.link(rel: "alternate", hreflang: locale, href: url)
    end
    if seo[:structured_data].present?
      tags << tag.script(json_escape(seo[:structured_data].to_json).html_safe, type: "application/ld+json")
    end
    if ENV["GOOGLE_SITE_VERIFICATION"].present?
      tags << tag.meta(name: "google-site-verification", content: ENV["GOOGLE_SITE_VERIFICATION"])
    end

    safe_join(tags, "\n")
  end

  def discovery_page_path(key, locale: I18n.locale)
    options = Seo::DiscoveryPage.path_options(key, locale)
    options[:slug].present? ? discovery_path(**options) : discovery_home_path(locale: options[:locale])
  end

  def play_timer_hot?(left, duration)
    duration = duration.to_i
    left = left.to_i
    duration.positive? && left.positive? && left <= duration * TIMER_HOT_RATIO
  end

  def play_timer_warn?(left, duration)
    duration = duration.to_i
    left = left.to_i
    duration.positive? && left.positive? && left <= duration * TIMER_WARN_RATIO && !play_timer_hot?(left, duration)
  end

  def night_title(night)
    night.primary_quiz_pack.copy(:title)
  end

  def night_qr_svg(night)
    RQRCode::QRCode.new(night_url(night.code)).as_svg(
      color: "091326",
      module_size: 5,
      shape_rendering: "crispEdges",
      standalone: true,
      use_path: true,
      viewbox: true
    ).html_safe
  end

  def night_poster_src(night_or_theme)
    if night_or_theme.is_a?(GameSession)
      artwork = night_or_theme.primary_quiz_pack&.questions&.first&.presentation&.[]("image")
      return media_src(artwork) if artwork.present?
    end

    file_id = night_or_theme.respond_to?(:theme_file_id) ? night_or_theme.theme_file_id : night_or_theme.to_s
    file_id = "reyes_y_profetas" if file_id.blank? || file_id == "kings_and_prophets"
    rel = "media/nights/#{file_id}.jpg"
    media_src(rel)
  end

  def ward_poster_src(ward)
    nights = ward.game_sessions
    night = nights.loaded? ? nights.max_by(&:updated_at) : nights.order(updated_at: :desc).first
    night_still_src(night)
  end

  def ward_country(ward)
    code = ward.country_code
    fallback = ward.try(:country_name).presence || code
    return fallback if code.blank?

    t("countries.#{code}", default: fallback)
  end

  def ward_picker_query(extra = {})
    {
      q: params[:q].presence,
      lat: params[:lat].presence,
      lng: params[:lng].presence,
      cambiar: params[:cambiar].presence,
      pick: params[:pick].presence || extra[:pick] || @picker_pick
    }.compact.merge(extra.except(:pick).compact)
  end

  def ward_place(ward)
    [ ward.city, ward_country(ward) ].compact_blank.join(", ")
  end

  def ward_street(ward)
    ward.try(:chapel_address).presence
  end

  def source_repo_url
    "https://github.com/tracyloisel/nochelive"
  end

  ABOUT_WHATSAPP_E164 = "34689226754"
  ABOUT_INSTAGRAM_HANDLE = "tracy_loisel"

  def about_whatsapp_url
    "https://wa.me/#{ABOUT_WHATSAPP_E164}"
  end

  def about_instagram_url
    "https://www.instagram.com/#{ABOUT_INSTAGRAM_HANDLE}/"
  end

  def about_portrait_src
    rel = "media/about/tracy.png"
    media_src(rel)
  end

  def night_still_src(night = nil, cinema: false)
    if night.is_a?(GameSession)
      pack = night.current_quiz_pack || night.primary_quiz_pack
      return street_still_src(pack.question_at(1)) if pack
    end

    night_poster_src(night.presence || "reyes_y_profetas")
  end

  def ceremony_still_src(night, cinema: false)
    night_still_src(night)
  end

  def temple_hall_bg_src
    %w[marble-hall temple-marble-hall].each do |base|
      %w[jpg webp png].each do |ext|
        rel = "media/temple/#{base}.#{ext}"
        return media_src(rel) if media_src(rel)
      end
    end

    "/media/ui/temple-marble-hall.svg"
  end

  def street_ceremony_asset_src(name)
    %w[jpg jpeg png webp svg].each do |ext|
      rel = "media/temple/#{name}.#{ext}"
      return media_src(rel) if media_src(rel)
    end

    nil
  end

  def church_still_src(name)
    belief_rel = "media/church/beliefs/#{name}-v2.png"
    return media_src(belief_rel) if media_src(belief_rel)

    rel = "media/church/#{name}.jpg"
    media_src(rel)
  end

  def paper_hall(id:, kicker:, extra_class: nil, sheet_class: nil, sheet: true, &block)
    render "shared/paper_hall",
      hall_id: id,
      kicker: kicker,
      extra_class: extra_class,
      sheet_class: sheet_class,
      sheet: sheet,
      body: capture(&block)
  end

  def chrome_menu(face: nil, hud: nil, bar: nil, theme: nil, &block)
    face = chrome_face? if face.nil?
    hud = chrome_hud?(face) if hud.nil?
    bar = chrome_hud_bar if hud && bar.nil?
    theme = normalize_hud_theme(theme || chrome_hud_theme)
    face = false if hud
    render "shared/chrome_menu", face: face, hud: hud, bar: bar, theme: theme, body: capture(&block)
  end

  def page_hud(**options, &block)
    content_for(:hud) { chrome_menu(**options, &block) }
  end

  def page_dock(active:)
    content_for(:dock) { render Navigation::DockComponent.new(active:) }
  end

  def chrome_hud?(face)
    return false unless face
    return false unless request
    css = content_for(:body_class).to_s
    return false if css.include?("is-street-play")

    true
  end

  def chrome_hud_bar
    Huds::Present.call(
      person: current_street_person,
      ward: current_ward,
      device_digest: street_device_digest
    )
  rescue NoMethodError
    Huds::Present.call(device_digest: "hud")
  end

  def chrome_hud_theme
    match = content_for(:body_class).to_s.match(/\bis-celestial-(light|dark)\b/)
    match ? "celestial-#{match[1]}" : "celestial-light"
  end

  def normalize_hud_theme(value)
    Hud::BarComponent.normalize_theme(value)
  end

  def site_menu(player: nil)
    render "shared/hub_menu", player: player || chrome_hud_bar
  end

  def chrome_face?
    chrome_tools_in_drawer?
  end

  def chrome_tools_in_drawer?
    css = content_for(:body_class).to_s
    css.include?("is-street-hub") || css.include?("is-paper-hall") || css.include?("is-street-play") || css.include?("is-study") || css.include?("is-church-journey") || css.include?("is-scripture-passage") || css.include?("is-church-videos")
  end

  def street_duel_ping?
    return false unless current_street_person

    css = content_for(:body_class).to_s
    street = css.include?("is-street-hub") || css.include?("is-street-play") || css.include?("is-paper-hall")
    night = css.include?("is-night-live") || css.include?("is-night-watch")
    street && !night
  end

  def home_night_path_for(night)
    night_path(night.code)
  end

  def night_status_caption(night)
    t("status.#{night.status}", default: t("status.finished"))
  end

  def band_label(position)
    key = case position
    when 1..3 then "discovery"
    when 4..6 then "competition"
    when 7..10 then "fire"
    when 11..13 then "chaos"
    when 14 then "semifinal"
    else "finale"
    end
    t("bands.#{key}")
  end


  def street_still_src(question)
    media_src(question&.presentation&.[]("image"))
  end

  def street_next_still(street)
    pack = street.pack
    ids = QuizDefinition.catalog.pack_ids
    if street.done?
      nxt = QuizDefinition.catalog.find_pack(ids[(ids.index(pack.id).to_i + 1) % ids.size])
      return street_still_src(nxt.question_at(1))
    end
    return unless street.settled?
    return street_still_src(pack.question_at(street.run.position + 1)) unless street.run.last_question?

    nxt = QuizDefinition.catalog.find_pack(ids[(ids.index(pack.id).to_i + 1) % ids.size])
    street_still_src(nxt.question_at(1))
  end

  def street_audio_data(run, question, extra_sfx: nil, extra_fx: nil, manual: false, ask_bed: nil, combo: nil)
    answer = run.quiz_answers.find_by(question_id: question.id)
    data = if run.finished?
      sfx = extra_sfx.presence || "street_royal_fanfare"
      fx = extra_fx.presence || "level"
      {
        stage_sfx_value: sfx,
        stage_sfx_token_value: "#{run.id}:done:#{sfx}",
        stage_fx_value: fx,
        stage_bed_value: nil,
        stage_bed_policy_value: nil,
        stage_timer_end_value: nil,
        stage_timer_duration_value: nil
      }
    end

    data ||= if answer
      grade = answer.correct? ? "correct" : "wrong"
      sfx = extra_sfx.presence || if answer.correct?
        "correct_gold"
      else
        "street_wrong_soft"
      end
      fx = extra_fx.presence || street_grade_fx(question, answer.correct?)
      {
        stage_sfx_value: sfx,
        stage_sfx_token_value: "#{run.id}:#{question.id}:settled:#{grade}",
        stage_fx_value: fx,
        stage_bed_value: ask_bed.presence,
        stage_bed_policy_value: ("continuous" if ask_bed.present?),
        stage_timer_end_value: nil,
        stage_timer_duration_value: nil
      }
    end

    data ||= begin
      timed = question.timed? && run.ends_at.present?
      sfx = extra_sfx.presence || (timed ? nil : (question.slam? ? "round_start" : "celestial_breath"))
      {
        stage_sfx_value: sfx,
        stage_sfx_token_value: "#{run.id}:#{question.id}:ask",
        stage_fx_value: extra_fx,
        stage_bed_value: ask_bed.presence || (timed ? "timer_tension" : nil),
        stage_bed_policy_value: ("continuous" if ask_bed.present?),
        stage_timer_end_value: timed ? run.ends_at.iso8601 : nil,
        stage_timer_duration_value: timed ? question.duration.to_i : nil
      }
    end

    if manual
      data[:stage_cue_policy_value] = "manual"
      data[:stage_fx_value] = nil
    end
    data
  end

  def street_quiz_shell_attributes(street:, overlay:, chrome:, combo:, extra_sfx: nil, extra_fx: nil)
    run = street.run
    question = street.question
    reward = street.reward
    last_gain = street.done? ? street.complete.last_gain.to_i : (street.settled? && street.answer&.correct? ? reward&.points_awarded.to_i : 0)
    from_score = last_gain.positive? ? [ run.score - last_gain, 0 ].max : run.score
    art_preview = overlay && street.asking? && run.asked_at.present? && run.asked_at.future?
    data = street_audio_data(
      run,
      question,
      extra_sfx:,
      extra_fx:,
      manual: overlay,
      ask_bed: ("timer_tension" if overlay),
      combo:
    ).merge(
      controller: [ "quiz", ("story" unless overlay), ("street-motion" if overlay && street.done?) ].compact.join(" "),
      story_street_value: (true unless overlay),
      street_motion_sequence_value: (overlay && street.done? ? "packComplete" : nil),
      quiz_correct_value: question.correct_choice,
      quiz_rewind_url_value: quiz_rewind_path(run),
      quiz_from_score_value: from_score,
      quiz_to_score_value: run.score,
      quiz_combo_shout_value: combo&.shout_key,
      quiz_streak_value: combo&.count.to_i,
      quiz_fire_cue_value: ("fire_whoosh" if overlay && street.settled? && street.answer&.correct? && combo&.count.to_i >= 2),
      quiz_preview_end_value: (run.asked_at.iso8601(3) if art_preview),
      quiz_theme: chrome&.mode,
      quiz_atmosphere: chrome&.atmosphere,
      quiz_glass: chrome&.glass,
      intensity: question.intensity,
      action: if overlay
        "pointerdown->quiz#revealArt pointerdown->quiz#startGesture click->quiz#pick turbo:submit-start->quiz#lock quiz:state->quiz#refreshStreetResult"
      else
        "pointerdown->quiz#revealArt pointerdown->story#start click->quiz#pick turbo:submit-start->quiz#lock"
      end
    ).compact
    classes = [
      "play-card", "play-reel", "is-quiz", "is-street",
      ("is-overlay" if overlay),
      ("is-art-preview" if art_preview),
      ("is-settled" if street.settled?),
      ("is-result-sequence" if overlay && street.settled? && !street.done?),
      ("is-done" if street.done?),
      ("is-ceremony" if overlay && street.done?),
      ("is-ceremony-immersive" if street.done? && !overlay),
      ("is-right" if street.settled? && street.answer&.correct?),
      ("is-wrong" if street.settled? && !street.answer&.correct?)
    ].compact
    { class: classes, data: }
  end

  def street_clock(seconds)
    total = [ seconds.to_i, 0 ].max
    format("%02d:%02d", total / 60, total % 60)
  end

  def ceremony_board_rows(board)
    rows = Array(board&.rows)
    top = rows.reject(&:context).first(3)
    you = rows.find { |row| row.you && row.context }
    return top if you.blank? || top.any?(&:you)

    top + [ you ]
  end

  def street_ceremony_verdict(complete:, impacts:)
    impacts = Array(impacts)
    score = t("chrome.crowns_count", count: complete.score.to_i)

    if impacts.one?
      item = impacts.first
      outcome = item.outcome.to_sym
      name = item.other.given_name
      gap = item.theirs.nil? ? nil : t("chrome.crowns_count", count: (item.mine.to_i - item.theirs.to_i).abs)
      return {
        tone: outcome,
        title: t("street.ceremony_verdict.duel.#{outcome}.title", name:),
        detail: t("street.ceremony_verdict.duel.#{outcome}.detail", name:, score:, gap:)
      }
    end

    if impacts.many?
      outcomes = %i[ahead behind tie waiting].filter_map do |outcome|
        count = impacts.count { |item| item.outcome.to_sym == outcome }
        t("street.ceremony_verdict.multi.outcomes.#{outcome}", count:) if count.positive?
      end
      tone = impacts.all? { |item| item.outcome.to_sym == :ahead } ? :ahead : :mixed
      return {
        tone:,
        title: outcomes.join(" · "),
        detail: t("street.ceremony_verdict.multi.detail", score:)
      }
    end

    answered = complete.answered.to_i
    correct = complete.correct.to_i
    tier = if answered.positive? && correct == answered
      :perfect
    elsif answered.positive? && correct * 5 >= answered * 4
      :mastered
    elsif answered.positive? && correct * 2 >= answered
      :solid
    else
      :retry
    end
    {
      tone: tier,
      title: t("street.ceremony_verdict.performance.#{tier}.title"),
      detail: t(
        "street.ceremony_verdict.performance.detail",
        correct:,
        answered:,
        score:
      )
    }
  end

  def street_choice_seed(run, question)
    run.id.to_i * 1_000 + question.position.to_i
  end

  def street_praise_line(run, question)
    lines = Array(I18n.t("street.praises"))
    lines = [ I18n.t("street.praise") ] if lines.empty?
    seed = 0
    "#{run.id}:#{question.id}".each_byte { |byte| seed = (seed * 33 + byte) & 0x7fffffff }
    lines[seed % lines.size]
  end

  def street_hit_shout(run, question, combo)
    key = combo&.shout_key
    return I18n.t("quiz.streak_#{key}") if key.present?
    return I18n.t("quiz.streak_continues") if combo&.respond_to?(:grew) && combo.grew

    street_praise_line(run, question)
  end

  def street_shuffled_choices(run, question)
    question.shuffled_choices(street_choice_seed(run, question))
  end

  def street_shuffled_tally(run, question, tally)
    order = street_shuffled_choices(run, question).map { |choice| choice_key(choice) }
    rows = Array(tally).index_by(&:key)
    order.filter_map { |key| rows[key] }
  end

  def street_next_rank(score)
    Team::RANKS.find { |threshold, _, _| score < threshold }&.last || Team::RANKS.last.last
  end

  def street_rank_level(score)
    idx = Team::RANKS.reverse.find_index { |threshold, _, _| score >= threshold }
    idx ? idx + 1 : 1
  end

  def street_rank_progress(score)
    current = Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first
    nxt = Team::RANKS.find { |threshold, _, _| score < threshold }
    return 100 unless nxt

    span = nxt[0] - current[0]
    return 100 if span <= 0

    (((score - current[0]) * 100) / span).clamp(0, 100)
  end

  def street_grade_fx(_question, _correct)
    nil
  end

  def mark_src(kind, key)
    return if key.blank?

    rel = "marks/#{kind}/#{key}.jpg"
    "/#{rel}" if Rails.public_path.join(rel).file?
  end

  def emblem_mark(key)
    mark_src("emblems", key)
  end

  def icon_mark(key)
    mark_src("icons", key)
  end

  def avatar_mark(record)
    key = record.is_a?(String) ? record : record&.avatar_key
    mark_src("avatars", key)
  end

  def street_live_dot(live)
    return unless live

    tag.span(class: "street-live-dot", title: t("street.live")) do
      tag.span(t("street.live"), class: "visually-hidden")
    end
  end

  def player_label(player, peers = nil)
    return player.name if player.blank?

    list = peers || player.game_session.players
    dupes = Array(list).count { |row| row.name.to_s.casecmp?(player.name.to_s) } > 1
    return player.name unless dupes

    extra = player.person&.family_name
    extra.present? ? "#{player.name} #{extra}" : player.name
  end

  def media_public_path(rel)
    return if rel.blank?

    rel = rel.to_s.delete_prefix("/")
    rel = "media/#{rel}" unless rel.start_with?("media/")
    rel if Rails.public_path.join(rel).file?
  end

  def media_src(rel, width: nil, format: "webp")
    return rel if rel.to_s.match?(/\Ahttps?:\/\//)

    logical = rel.to_s.delete_prefix("/")
    logical = "media/#{logical}" unless logical.start_with?("media/")
    if (asset = Frontend::MediaManifest.fetch_path(rel) || Frontend::MediaManifest.fetch_path(logical))
      variants = asset.fetch("variants").fetch(format)
      variant = if width
        variants.find { |candidate| candidate.fetch("width") >= width.to_i } || variants.last
      else
        variants.last
      end
      return variant.fetch("src")
    end

    path = media_public_path(rel)
    return unless path

    webp = path.sub(/\.[^.]+\z/, ".webp")
    if request&.headers&.[]("HTTP_ACCEPT").to_s.include?("image/webp") && Rails.public_path.join(webp).file?
      path = webp
    end

    "/#{path}" if path
  end

  CHOICE_MARKS = [
    { shape: "circle", tone: "gold" },
    { shape: "square", tone: "fire" },
    { shape: "triangle", tone: "navy" },
    { shape: "star", tone: "deep" }
  ].freeze

  def picto(name, size: nil)
    render "shared/picto", name: name.to_s, size: size
  end

  def church_video_duration(value)
    seconds = [ value.to_i, 0 ].max
    hours, remainder = seconds.divmod(3600)
    minutes, seconds = remainder.divmod(60)
    hours.positive? ? format("%d:%02d:%02d", hours, minutes, seconds) : format("%d:%02d", minutes, seconds)
  end

  def locale_flag(code)
    picto(Locale.flag(code))
  end

  def choice_mark(index)
    CHOICE_MARKS[index.to_i % CHOICE_MARKS.size]
  end

  def choice_key(choice)
    if choice.is_a?(Hash)
      (choice["key"] || choice[:key] || choice["label"] || choice[:label]).to_s
    else
      choice.to_s
    end
  end

  def choice_label(choice, definition = nil)
    return definition.choice_copy(choice) if definition

    if choice.is_a?(Hash)
      (choice["label"] || choice[:label] || choice["key"] || choice[:key]).to_s
    else
      choice.to_s
    end
  end

  def rank_name(label_or_key)
    raw = label_or_key.to_s
    key = Team::RANKS.find { |_, rank_key, label| rank_key == raw || label == raw }&.second
    key ||= "rey" if raw.casecmp("Rey").zero? || raw.casecmp("King").zero?
    return raw if key.blank?

    t("ranks.#{key}")
  end

  def emblem_name(key)
    t("emblems.#{key}", default: Team::EMBLEMS[key.to_s])
  end

  def avatar_name(key)
    t("avatars.#{key}", default: key.to_s.capitalize)
  end

  def street_next_rank(score)
    Team::RANKS.find { |threshold, _, _| score < threshold }&.third || Team::RANKS.last.third
  end

  def street_rank_level(score)
    idx = Team::RANKS.reverse.find_index { |threshold, _, _| score >= threshold }
    idx ? idx + 1 : 1
  end

  def street_rank_progress(score)
    current = Team::RANKS.reverse.find { |threshold, _, _| score >= threshold } || Team::RANKS.first
    nxt = Team::RANKS.find { |threshold, _, _| score < threshold }
    return 100 unless nxt

    span = nxt[0] - current[0]
    return 100 if span <= 0

    (((score - current[0]) * 100) / span).clamp(0, 100)
  end

  def street_xp_cap(score)
    Team::RANKS.find { |threshold, _, _| score < threshold }&.first
  end

  def street_xp_remaining(score)
    cap = street_xp_cap(score)
    return if cap.nil?

    left = cap - score.to_i
    left.positive? ? left : nil
  end

  def hub_live_when(live, now: Time.current)
    starts = live.starts_at
    return if starts.blank? || live.state.to_sym == :playing

    t("hub.live_when", day: I18n.l(starts, format: "%A").capitalize, time: hub_live_clock_time(starts))
  end

  def hub_live_clock_time(starts)
    case I18n.locale.to_s
    when "fr", "pt-BR"
      starts.min.zero? ? I18n.l(starts, format: "%Hh") : I18n.l(starts, format: "%Hh%M")
    when "en"
      I18n.l(starts, format: "%l:%M%P").strip.sub(/:00(?=[ap]m\z)/i, "")
    else
      I18n.l(starts, format: "%H:%M")
    end
  end

  def compact_number(value, decimals: 1)
    return value if value.nil? || value.to_s == "0"
    n = value.to_f
    return "0" if n.zero?

    abs_n = n.abs
    if abs_n >= 1_000_000_000
      suffix = "B"
      divisor = 1_000_000_000
    elsif abs_n >= 1_000_000
      suffix = "M"
      divisor = 1_000_000
    elsif abs_n >= 1_000
      suffix = "K"
      divisor = 1_000
    else
      return number_with_delimiter(value.to_i)
    end

    formatted = (n / divisor).round(decimals)
    # Remove trailing zero if decimals specified (e.g., 3.0K → 3K, but 3.5K stays)
    formatted = formatted.to_i if formatted == formatted.to_i
    "#{formatted}#{suffix}"
  end

  def scripture_read_count_label(count)
    delimiter = case I18n.locale.to_s
    when "fr" then "\u202F"
    when "es", "pt-BR" then "."
    else ","
    end
    formatted = number_with_delimiter(count.to_i, delimiter:)
    t("seo.scripture.reads", count: count.to_i, formatted:)
  end

  def scripture_reader_chapter_title(chapter, study)
    psalm_number = study.to_s[/\Aot\/ps\/(\d+)\z/, 1]
    return chapter.title unless psalm_number

    t("scripture_reader.psalm_title", number: psalm_number)
  end

  def scripture_reader_reference_label(study)
    reference = Scriptures::Reference.from_study(study:, locale: I18n.locale, verse: 1)
    return study unless reference
    return t("scripture_reader.psalm_title", number: reference.chapter) if reference.base_study == "ot/ps"

    "#{reference.book_label} #{reference.chapter}"
  end

  def scripture_reader_citation_label(chapter_title, verses)
    chapter_title = chapter_title.to_s.strip
    verses = verses.to_s.strip.tr("-", "–")
    return chapter_title if verses.blank?

    "#{chapter_title}:#{verses}"
  end

  def liga_number(value)
    delimiter = case I18n.locale.to_s
    when "fr" then "\u202F"
    when "es", "pt-BR" then "."
    else ","
    end
    number_with_delimiter(value.to_i, delimiter:)
  end
end
