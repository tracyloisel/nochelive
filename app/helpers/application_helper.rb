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
    "live_presenter" => "surfaces/live",
    "stats" => "surfaces/stats",
    "ward_profile" => "surfaces/profile",
    "study" => "surfaces/study",
    "scripture" => "surfaces/scripture",
    "church" => "surfaces/church",
    "onboarding" => "surfaces/onboarding",
    "profile" => "surfaces/profile",
    "identity" => "surfaces/identity"
  }.freeze

  FRONTEND_CONTROLLER_STYLES = {
    "church_videos" => %w[church],
    "discovery" => %w[church],
    "fichas" => %w[profile],
    "game_sessions" => %w[profile],
    "home" => %w[hub onboarding],
    "identity_transfers" => %w[identity],
    "notification_settings" => %w[profile],
    "pages" => %w[church],
    "players" => %w[live onboarding],
    "presenter/claims" => %w[live onboarding],
    "presenter/gates" => %w[live onboarding],
    "presenter/rosters" => %w[live onboarding],
    "public" => %w[gameplay live],
    "scriptures" => %w[scripture],
    "searches" => %w[church],
    "street_hub" => %w[hub onboarding],
    "street_leaderboards" => %w[stats],
    "street_profiles" => %w[profile],
    "study_communities" => %w[study],
    "study_histories" => %w[study],
    "study_programs" => %w[study],
    "study_runs" => %w[study scripture],
    "study_units" => %w[study scripture],
    "ward_adds" => %w[church],
    "ward_gates" => %w[profile],
    "ward_memories" => %w[profile],
    "ward_profiles" => %w[profile],
    "wards" => %w[profile]
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

  def noche_picture(key, role: nil, alt:, class_name: nil, picture_class: nil, loading: "lazy", decoding: "async", fetchpriority: nil, data: {})
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
          sizes: rendition.fetch("sizes")
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
      sizes: primary.fetch("sizes"),
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

    image_attributes = attributes.slice(:alt, :loading, :decoding, :fetchpriority, :data)
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
    night.definition.theme.copy(:title)
  rescue GameDefinition::Error
    night.theme_title
  end

  def night_poster_src(night_or_theme)
    if night_or_theme.is_a?(GameSession) && night_or_theme.poster_path.present?
      custom_rel = night_or_theme.poster_path.delete_prefix("/")
      return media_src(custom_rel) if Frontend::MediaManifest.fetch_source(custom_rel) || Rails.public_path.join(custom_rel).file?
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
      round = night.current_round_run
      round ||= Array(night.round_runs).max_by { |run| run.position.to_i }
      src = challenge_story(round, cinema: cinema) if round
      return src if src.present?
      return night_poster_src(night)
    end

    night_poster_src(night.presence || "reyes_y_profetas")
  end

  def ceremony_still_src(night, cinema: false)
    ceremony_rel = cinema ? "media/stories/salomon_wisdom_night_wide.png" : "media/stories/salomon_wisdom_night_portrait.png"
    return media_src(ceremony_rel) if media_src(ceremony_rel)

    Array(night&.round_runs).sort_by { |run| -run.position.to_i }.each do |run|
      src = challenge_story(run, cinema: cinema)
      return src if src.present?
    end
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

  def story_reel(**kwargs, &block)
    render "shared/reel", **kwargs, body: capture(&block)
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
    night = css.include?("is-play") || css.include?("is-watch") || css.include?("is-presenter")
    street && !night
  end

  def home_night_path_for(night)
    night.finished? ? ward_memory_path(night.ward.code, night.code) : night_name_path(night.code)
  end

  def presenter_next_action(night, round)
    return { label: t("presenter.actions.start"), url: presenter_start_path(night.code) } if night.lobby?
    return { label: t("presenter.actions.resume"), url: presenter_resume_path(night.code) } if night.paused?
    return if night.finished? || round.nil?
    return unless round.live? || !round.completed?

    definition = round.definition
    layered = definition.layered_finale?

    if layered && (round.pending? || (round.intro? && round.layer_index.to_i.zero?))
      return { label: t("presenter.actions.serve"), url: presenter_open_round_path(night.code, round) }
    end
    if layered && round.intro? && !round.last_layer?
      return { label: t("presenter.actions.next_layer"), url: presenter_peel_round_path(night.code, round) }
    end
    if layered && round.burger_assembled?
      return { label: t("presenter.actions.the_question"), url: presenter_open_round_path(night.code, round) }
    end
    if round.pending? || round.intro?
      return { label: t("presenter.actions.open"), url: presenter_open_round_path(night.code, round) }
    end

    show_crown = definition.finale? && !night.finished? && !round.completed? && !round.pending?
    show_crown &&= !layered || round.phase.in?(%w[open locked answering revealed])
    return { label: t("presenter.actions.crown"), url: presenter_crown_path(night.code, round) } if show_crown

    if round.open?
      if definition.freeze?
        return { label: t("presenter.actions.freeze"), url: presenter_lock_round_path(night.code, round) }
      elsif definition.vote?
        return { label: t("presenter.actions.count_votes"), url: presenter_lock_round_path(night.code, round) }
      elsif definition.buzzer? && !definition.finale?
        return { label: t("presenter.actions.close_buzz"), url: presenter_lock_round_path(night.code, round) }
      elsif definition.finale?
        return { label: t("presenter.actions.close_crown"), url: presenter_lock_round_path(night.code, round) }
      else
        return { label: t("presenter.actions.close_round"), url: presenter_lock_round_path(night.code, round) }
      end
    end

    if round.phase.in?(%w[locked answering])
      return { label: t("presenter.actions.reveal"), url: presenter_reveal_round_path(night.code, round) }
    end
    if round.revealed?
      { label: t("presenter.actions.next"), url: presenter_complete_round_path(night.code, round) }
    end
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

  def round_prompt(round)
    definition = round.definition
    definition.copy(:question).presence || definition.copy(:instructions)
  end

  def stage_sfx(round, extra = nil, team: nil, night: nil, pulse: nil)
    return extra if extra.present?
    return "level_up" if team&.pending_rank_up.present?
    return "royal_fanfare" if night&.finished?
    kind = pulse.is_a?(Hash) ? (pulse[:kind] || pulse["kind"]) : nil
    return if %w[open advance lock reveal freeze score miss].include?(kind.to_s)
    return unless round

    definition = round.definition
    if definition.layered_finale? && round.intro?
      if round.layer_index.to_i.zero? || round.last_layer?
        cue = definition.sfx["intro"].presence || "dramatic_fire"
        return cue if Sfx.known?(cue)
      end

      return
    end

    case round.phase
    when "intro" then definition.sfx["intro"].presence || "question_change"
    end
  end

  def stage_sfx_token(round, sfx = nil, extra = nil, team: nil, night: nil)
    [ sfx, extra, team&.pending_rank_up, night&.id, night&.status, round&.id, round&.phase, round&.try(:layer_index) ].compact.join(":")
  end

  def stage_bed(round, night: nil)
    return if night&.finished?
    return unless round&.timed? && round.seconds_left.positive?

    "timer_tension"
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

  def stage_audio_data(round, extra_sfx = nil, extra_fx = nil, team: nil, night: nil, pulse: nil)
    sfx = stage_sfx(round, extra_sfx, team: team, night: night, pulse: pulse)
    timed = round&.timed?
    {
      stage_sfx_value: sfx,
      stage_sfx_token_value: stage_sfx_token(round, sfx, extra_sfx, team: team, night: night),
      stage_fx_value: stage_fx(round, extra_fx, team: team, night: night),
      stage_bed_value: stage_bed(round, night: night),
      stage_timer_end_value: timed && round.ends_at ? round.ends_at.iso8601 : nil,
      stage_timer_duration_value: timed ? round.definition.duration.to_i : nil
    }
  end

  def stage_fx(round, extra = nil, team: nil, night: nil)
    return extra if extra.present?
    return "level" if team&.pending_rank_up.present?
    return "finale" if night&.finished?
    return "shake" if round&.locked? && round.definition.freeze?

    round&.revealed? ? "reveal" : nil
  end

  def medal_label(position)
    I18n.t("ordinals.#{position}", default: I18n.t("ordinals.other", n: position))
  end

  def latency_label(ms)
    return if ms.blank?

    "#{ms.to_i} ms"
  end

  def team_roster(team)
    Array(team&.players).select(&:participant?).map(&:name).reject(&:blank?)
  end

  def roster_line(team)
    names = team_roster(team)
    return if names.empty?

    names.to_sentence
  end

  def missionary_line(night)
    names = Array(night&.missionaries).map(&:name).reject(&:blank?)
    return if names.empty?

    names.to_sentence
  end

  def finale_blessing
    t("lines.blessing")
  end

  def vote_tally_line(round, counts: nil)
    counts ||= round.ballots.group(:choice_team_id).count
    return if counts.empty?

    top = counts.values.max
    names = Team.where(id: counts.select { |_id, votes| votes == top }.keys).order(:name).pluck(:name)
    return if names.empty?
    return t("lines.wisdom_one", name: names.first) if names.size == 1

    t("lines.wisdom_many", names: names.to_sentence)
  end

  def rank_up_shout(team)
    return if team.pending_rank_up.blank?

    rank = rank_name(team.pending_rank_up)
    return t("lines.rank_king", name: team.name, rank: rank) if team.rey?

    t("lines.rank", name: team.name, rank: rank)
  end

  def night_leader_line(night)
    champs = night.first_place_teams
    return if champs.empty?
    return t("lines.tied", names: champs.map(&:name).to_sentence) if night.tied_finale?

    t("lines.leader", name: night.champion.name)
  end

  def player_remote?(player)
    player&.remote?
  end

  def phone_quiz?(round, player)
    definition = round&.definition
    return false unless definition
    return false if definition.layered_finale?
    return true if definition.choice?

    player_remote?(player) && definition.buzzer? && definition.has_choices?
  end

  def phone_quiz_asking?(round, player)
    return false unless round
    return round.open? if round.definition.choice?

    phone_quiz?(round, player) && round.phase.in?(%w[open locked answering])
  end

  def team_explainer(team)
    return if team&.solo?

    team.players.min_by(&:id)
  end

  def explainer?(team, player)
    return false if team&.solo? && player_remote?(player)

    player && team_explainer(team)&.id == player.id
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

  def challenge_media_id(round)
    round&.definition&.id
  end

  def challenge_clip(round)
    layered = burger_clip(round)
    return layered if layered

    id = challenge_media_id(round)
    return unless id

    rel = "media/challenges/#{id}/clip.mp4"
    rel if Rails.public_path.join(rel).file?
  end

  def challenge_story(round, cinema: false)
    definition = round&.definition
    return unless definition

    if (layer = burger_layer_for(round))
      src = media_src(layer["image"])
      return src if src
    end

    presentation = definition.presentation || {}
    yaml_rel = (presentation["image_wide"] if cinema).presence || presentation["image"].presence
    if yaml_rel
      src = media_src(yaml_rel)
      return src if src
    end

    id = definition.id
    %w[jpg jpeg png webp].each do |ext|
      rel = "media/stories/#{id}.#{ext}"
      return media_src(rel) if media_src(rel)
    end
    nil
  end

  def burger_layer_for(round)
    definition = round&.definition
    return unless definition&.layered_finale?

    round.current_layer || definition.layers.find { |layer| layer["key"] == "chariot" } || definition.layers[2]
  end

  def burger_clip(round)
    layer = burger_layer_for(round)
    rel = media_public_path(layer&.[]("clip"))
    rel
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

  def burger_stakes_line(night, you = nil)
    scores = Team.where(game_session_id: night.id).pluck(:cached_score)
    return t("lines.burger_can") if you.nil?

    best = scores.max || 0
    tied = scores.count { |score| score == best } > 1
    me = you.cached_score.to_i
    return t("lines.burger_tie") if tied && me == best
    return t("lines.burger_close") if me == best

    t("lines.burger_pass")
  end

  def burger_host_value_line(night, round)
    team = round.answering_team
    if team.nil? && round.finale_steal_open?
      remote_teams = night.teams.select { |row| row.players.any? { |player| player.participant? && player.remote? } }
      team = remote_teams.first if remote_teams.size == 1
    end
    points = team ? round.definition.swing_points(night, team) : round.definition.points
    t("lines.burger_value", points: points)
  end

  def burger_watch_steal_line(night)
    casa = night.teams.select { |team| team.players.any? { |player| player.participant? && player.remote? } }
    casa.size == 1 ? t("lines.burger_steal_one") : t("lines.burger_steal")
  end

  def burger_garnish_kind(round)
    return unless round&.definition&.layered_finale?
    return "nugget" if round.finale_steal_open?
    return "fry" if round.anyone_correct?

    index = round.layer_index.to_i
    return "fry" if index <= 0 || round.last_layer? || round.phase.in?(%w[open locked answering])
    return "lettuce" if index <= 2

    "nugget"
  end

  def burger_garnish_count(round, cinema: false)
    kind = burger_garnish_kind(round)
    return 0 unless kind

    index = round.layer_index.to_i
    heavy = if round.finale_steal_open?
      28
    elsif kind == "lettuce" && index == 2
      24
    elsif kind == "lettuce"
      8
    elsif index <= 0
      8
    else
      18
    end
    cinema ? heavy : [ (heavy / 3.0).ceil, 4 ].max
  end

  def chapel_players(night)
    night.players.participants.where(location: "room").includes(:team).order(:id).to_a
  end

  def burger_cheer_targets(night)
    faces = chapel_players(night)
    return { mode: :empty, faces: [], teams: [] } if faces.empty?
    return { mode: :emblems, faces: [], teams: chapel_cheer_teams(night, faces) } if faces.size >= 9

    { mode: :faces, faces: faces, teams: [] }
  end

  def chapel_cheer_teams(night, faces)
    ids = faces.map(&:team_id).uniq
    night.teams.includes(:players).where(id: ids).order(:name)
  end

  def cheer_to_you_line(names)
    names = Array(names).map(&:to_s).reject(&:blank?).uniq
    return if names.empty?

    t("play.cheer_you", count: names.size, names: names.to_sentence)
  end

  def layer_cheers(round)
    return Cheer.none unless round

    round.cheers.where(layer_index: round.layer_index).includes(:player, :to_player)
  end

  def challenge_slides(round)
    id = challenge_media_id(round)
    return [] unless id

    dir = Rails.public_path.join("media/challenges/#{id}/slides")
    return [] unless dir.directory?

    dir.children.select { |path| path.file? && path.extname.downcase.in?(%w[.jpg .jpeg .png .webp]) }
       .sort
       .map { |path| "/media/challenges/#{id}/slides/#{path.basename}" }
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

  def answer_body_label(round, answer)
    definition = round.definition
    if definition.ordering?
      definition.order_labels(answer.body).join(" → ")
    elsif definition.mime? && definition.story_path?
      definition.path_labels(answer.body).join(" → ")
    elsif definition.freeze?
      "#{answer.body.to_i} ms"
    elsif Array(definition.choices).any?
      row = Array(definition.choices).find { |choice| choice_key(choice) == answer.body.to_s }
      row ? choice_label(row, definition) : answer.body
    else
      answer.body
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

  SCORE_REASON_KEYS = {
    "Respuesta incorrecta" => "scores.incorrect",
    "Respuesta correcta" => "scores.correct",
    "Correcta con corona ×2" => "scores.crown",
    "Primer buzz" => "scores.first_buzz",
    "Estatua sostenida" => "scores.statue",
    "Piedra lanzada" => "scores.stone",
    "Fuego de Elías" => "scores.chest_fuego",
    "Escudo de David" => "scores.chest_escudo",
    "Sabiduría" => "scores.chest_sabiduria",
    "Ajuste del presentador +5" => "scores.presenter_plus",
    "Ajuste del presentador −5" => "scores.presenter_minus"
  }.freeze

  def score_reason_label(reason)
    raw = reason.to_s
    return t(raw) if raw.start_with?("scores.")

    key = SCORE_REASON_KEYS[raw]
    key ? t(key) : raw
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

  def liga_number(value)
    delimiter = case I18n.locale.to_s
    when "fr" then "\u202F"
    when "es", "pt-BR" then "."
    else ","
    end
    number_with_delimiter(value.to_i, delimiter:)
  end
end
