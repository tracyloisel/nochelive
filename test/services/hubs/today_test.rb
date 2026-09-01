require "test_helper"

class Hubs::TodayTest < ActiveSupport::TestCase
  Week = Struct.new(:id, :status, :starts_on, :ends_on, :theme_copy, :period, keyword_init: true) do
    def theme(_locale) = theme_copy
    def display_period(_locale) = period
  end
  Expedition = Struct.new(
    :state, :packs, :title, :study_unit_id, :starts_on, :ends_on,
    keyword_init: true
  )
  Pack = Struct.new(:id, :state, :title, :hook, :lede, :kicker, :artwork, keyword_init: true)

  setup do
    @starts_on = Date.new(2044, 8, 29)
    @week = Week.new(
      id: 741,
      status: "published",
      starts_on: @starts_on,
      ends_on: @starts_on + 6.days,
      theme_copy: "Les Psaumes de la semaine",
      period: "29 août – 4 septembre"
    )
  end

  test "a playing or imminent Live is the only first priority and states its timing honestly" do
    %i[playing imminent].each do |state|
      live = Hubs::Screen::Live.new(
        state:,
        starts_at: Time.zone.parse("2044-08-30 20:00:00"),
        title: "David · Elie",
        join_path: ("/noches/LIVE" if state == :playing),
        program_path: "/ramas/RAMA",
        still: "/media/live.webp",
        theme_mode: "dark",
        theme_atmosphere: "dramatic"
      )

      item = select_today(live:, study: study(daily_discovery: daily_discovery))

      assert_equal(state == :playing ? :live : :live_upcoming, item.kind)
      assert_equal state, item.state
      assert_equal "David · Elie", item.title
      assert_equal(state == :playing ? "/noches/LIVE" : "/ramas/RAMA", item.path)
      assert_equal "dark", item.theme_mode
      assert_equal "dramatic", item.theme_atmosphere
      assert_nil item.action_label
    end
  end

  test "the approved daily discovery beats expedition and reading content with canonical scripture routing" do
    scheduled_live = Hubs::Screen::Live.new(
      state: :scheduled,
      starts_at: 5.days.from_now,
      title: "Programme de la semaine"
    )
    item = select_today(live: scheduled_live, study: study(daily_discovery: daily_discovery))

    assert_equal :daily_discovery, item.kind
    assert_equal :discovery, item.state
    assert_equal "Aujourd'hui dans les Ecritures", item.eyebrow
    assert_equal "Un roi devient pretre.", item.title
    assert_equal "Le poeme reunit deux roles.", item.setup
    assert_equal "Pourquoi Melchisedek apparait-il ici ?", item.question
    assert_equal "Psaumes 110", item.cite
    assert_equal "scripture.library.daily.ps110", item.artwork
    assert_equal "Entrer dans le mystere", item.action_label
    assert_equal @starts_on, item.scheduled_on

    uri = URI.parse(item.path)
    assert_equal "/escrituras/ot/ps/110", uri.path
    assert_equal "fr", Rack::Utils.parse_nested_query(uri.query).fetch("locale")
  end

  test "daily contemplation uses the same merged weekly route and citation as the Library" do
    discovery = daily_discovery(
      kind: "contemplation",
      reference: "ot/ps/102",
      references: %w[ot/ps/102 ot/ps/110 ot/ps/119]
    )

    item = select_today(study: study(daily_discovery: discovery))

    assert_equal :contemplation, item.state
    assert_equal "Psaumes 102–119", item.cite
    uri = URI.parse(item.path)
    query = Rack::Utils.parse_nested_query(uri.query)
    assert_equal "/bibliotheque", uri.path
    assert_equal "weekly", query.fetch("section")
    assert_equal @week.id.to_s, query.fetch("unit")
    assert_equal "cette-semaine", uri.fragment
  end

  test "the first unfinished door of an active expedition beats the weekly programme" do
    finished = expedition_pack(id: "first", state: :finished, title: "La voix perdue")
    next_door = expedition_pack(
      id: "second",
      state: :open,
      title: "Le Roi sans nom",
      hook: "Un roi, deux offices.",
      lede: "Ce texte ouvre une porte.",
      kicker: "Psaume 110"
    )
    expedition = Expedition.new(
      state: :active,
      packs: [ finished, next_door ],
      title: "Six portes dans les Psaumes",
      study_unit_id: @week.id,
      starts_on: @week.starts_on,
      ends_on: @week.ends_on
    )

    item = select_today(study: study(expedition:))

    assert_equal :expedition, item.kind
    assert_equal :open, item.state
    assert_equal next_door.title, item.title
    assert_equal next_door.hook, item.body
    assert_equal next_door.kicker, item.cite
    assert_equal "Six portes dans les Psaumes", item.meta
    assert_equal Rails.application.routes.url_helpers.street_map_path(
      view: "expeditions",
      expedition: @week.id
    ), item.path
    assert_nil item.action_label
  end

  test "the first unfinished weekly reading beats a published Rama event" do
    completed = weekly_reading(study: "ot/ps/102", status: :completed, progress_percent: 100)
    unread = weekly_reading(study: "ot/ps/110", status: :unread, progress_percent: nil)

    item = select_today(
      study: study(expedition: nil, weekly_reading_cards: [ completed, unread ]),
      rama_events: [ rama_event ]
    )

    assert_equal :weekly_reading, item.kind
    assert_equal :unread, item.state
    assert_equal unread.title, item.title
    assert_equal unread.cite, item.cite
    assert_equal unread.study, item.source_id
    uri = URI.parse(item.path)
    assert_equal "/escrituras/ot/ps/110", uri.path
    query = Rack::Utils.parse_nested_query(uri.query)
    assert_equal @week.id.to_s, query.fetch("study_unit_id")
    assert_equal "fr", query.fetch("locale")
    assert_nil item.action_label
  end

  test "a completed reading set falls back to the real published weekly programme" do
    completed = weekly_reading(study: "ot/ps/102", status: :completed, progress_percent: 100)

    item = select_today(study: study(expedition: nil, weekly_reading_cards: [ completed ]))

    assert_equal :weekly_program, item.kind
    assert_equal :published, item.state
    assert_equal @week.theme_copy, item.title
    assert_equal @week.period, item.meta
    assert_equal completed.artwork, item.artwork
    assert_equal @week.starts_on, item.starts_on
    assert_equal @week.ends_on, item.ends_on
    assert_nil item.action_label
  end

  test "the next published non-cancelled Rama event is selected without a dashboard count" do
    cancelled = rama_event(event_id: 1, state: :cancelled, starts_at: 1.hour.from_now)
    published = rama_event(
      event_id: 2,
      state: :published,
      title: "Collecte alimentaire",
      starts_at: 2.hours.from_now,
      external: true,
      path: "https://example.org/collecte"
    )

    item = select_today(study: nil, rama_events: [ cancelled, published ])

    assert_equal :rama_event, item.kind
    assert_equal :published, item.state
    assert_equal published.title, item.title
    assert_equal published.summary, item.body
    assert_equal published.location_label, item.meta
    assert_equal published.starts_at, item.starts_at
    assert_equal published.event_id, item.source_id
    assert item.external
    assert_nil item.action_label
  end

  test "a player without a Rama or current programme gets an honest fallback without duplicating the hero" do
    live = Hubs::Screen::Live.new(state: :ward_missing)

    item = select_today(live:, study: nil, rama_events: [])

    assert_equal :fallback, item.kind
    assert_equal :available, item.state
    assert_nil item.scheduled_on
    assert_nil item.title
    assert_nil item.body
    assert_nil item.artwork
    assert_nil item.path
    assert_nil item.method
    assert_nil item.action_label
  end

  private

    def select_today(live: Hubs::Screen::Live.new(state: :none), study: nil, rama_events: [])
      Hubs::Today.call(live:, study:, rama_events:, locale: :fr)
    end

    def study(daily_discovery: nil, expedition: default_expedition, weekly_reading_cards: [ weekly_reading ])
      Hubs::Screen::Study.new(
        week: @week,
        weekly_reading_cards:,
        expedition:,
        daily_discovery:
      )
    end

    def daily_discovery(kind: "discovery", reference: "ot/ps/110", references: [ "ot/ps/110" ])
      Expeditions::DailyDiscovery::Result.new(
        id: "daily-psalm-110",
        kind:,
        scheduled_on: @starts_on,
        time_zone: "Europe/Madrid",
        locale: "fr",
        pack_id: ("exp_psalms_nameless_king" if kind == "discovery"),
        reference:,
        references:,
        claim_ids: [ "exeg-004" ],
        eyebrow: "Aujourd'hui dans les Ecritures",
        title: "Un roi devient pretre.",
        setup: "Le poeme reunit deux roles.",
        question: "Pourquoi Melchisedek apparait-il ici ?",
        cta_label: "Entrer dans le mystere",
        artwork_key: "scripture.library.daily.ps110",
        light_family: "celestial_dark",
        depiction_mode: "symbolic_atmosphere",
        certainty: "DISCUTE",
        disclosure: "Illustration dramatisee.",
        alt: "Une couronne et une lampe.",
        motion: "still",
        audio: "silent"
      )
    end

    def default_expedition
      Expedition.new(
        state: :active,
        packs: [ expedition_pack ],
        title: "Six portes dans les Psaumes",
        study_unit_id: @week.id,
        starts_on: @week.starts_on,
        ends_on: @week.ends_on
      )
    end

    def expedition_pack(id: "door", state: :available, title: "Les harpes suspendues", hook: nil, lede: "Pourquoi se taire ?", kicker: "Psaume 137")
      Pack.new(
        id:,
        state:,
        title:,
        hook:,
        lede:,
        kicker:,
        artwork: "quizzes/expedition/harps.webp"
      )
    end

    def weekly_reading(study: "ot/ps/102", status: :unread, progress_percent: nil)
      reference = Scriptures::Reference.from_study(study:, locale: :fr, verse: 1)
      title = "#{reference.book_label} #{reference.chapter}"
      Hubs::WeeklyReadingCards::Card.new(
        study:,
        cite: title,
        title:,
        artwork: "media/study/psalms.webp",
        status:,
        progress_percent:,
        study_unit_id: @week.id
      )
    end

    def rama_event(event_id: 7, state: :published, title: "Activite de Rama", starts_at: 1.day.from_now, external: false, path: "/ramas/RAMA")
      Hubs::RamaEvents::Card.new(
        event_id:,
        kind: :food_drive,
        state:,
        title:,
        summary: "Apporte ce que tu peux.",
        cancellation_reason: ("Annulee" if state == :cancelled),
        starts_at:,
        location_label: "Salle paroissiale",
        path:,
        external:,
        still: "/media/church/worship.jpg"
      )
    end
end
