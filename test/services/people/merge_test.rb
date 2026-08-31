require "test_helper"

class People::MergeTest < ActiveSupport::TestCase
  test "moves players and devices onto the keeper then destroys the source" do
    night = game_sessions(:elias)
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    player = Players::Join.call(
      night:,
      name: "Carmen",
      device_token: "lopez-phone",
      person: source
    )

    People::Merge.call(keeper:, source:)

    assert_equal keeper, player.reload.person
    assert_not Person.exists?(source.id)
    assert PersonDevice.exists?(person: keeper, device_token: "lopez-phone")
  end

  test "consolidates activity when both profiles played in the same night" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    keeper_player = players(:lucia)
    source_player = players(:daniel)
    keeper_player.update!(person: keeper)
    source_player.update!(person: source)
    run = QuizRun.create!(
      person: source,
      game_session: source_player.game_session,
      player: source_player,
      team: source_player.team,
      live_sequence_position: 1,
      device_digest: "source-live-run",
      pack_id: "coronas",
      position: 3,
      score: 24,
      opened_at: Time.current,
      status: "open"
    )

    People::Merge.call(keeper:, source:)

    assert_not Player.exists?(source_player.id)
    assert_equal keeper, keeper_player.reload.person
    assert_equal keeper_player, run.reload.player
    assert_equal 24, run.score
  end

  test "preserves viral attribution when the source profile is merged" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    event = ViralEvent.create!(
      name: "invitee_profile_created",
      device_digest: "merged-invitee-device",
      duel_invitation: duel_invitations(:open_pili_invitation),
      person: source,
      source: "invite"
    )

    People::Merge.call(keeper:, source:)

    assert_equal keeper, event.reload.person
    assert_not Person.exists?(source.id)
    assert_equal "invitee_profile_created", keeper.viral_events.find(event.id).name
  end

  test "preserves quiz points from the newer duplicate" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    run = QuizRun.create!(
      person: source,
      device_digest: "new-carmen-phone",
      pack_id: "coronas",
      position: 10,
      score: 150,
      opened_at: 1.day.ago,
      status: "finished"
    )

    People::Merge.call(keeper:, source:)

    assert_equal keeper, run.reload.person
    assert_equal 270, Quizzes::Leaderboard.pack_best_totals(ward: keeper.ward)[keeper.id]
  end

  test "moves study quizzes and consolidates reading progress before deleting the duplicate" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    unit, quiz = create_study
    study_run = StudyRun.create!(
      person: source,
      study_quiz_version: quiz,
      device_digest: "new-carmen-study",
      position: 10,
      score: 9,
      status: "completed",
      opened_at: 2.days.ago,
      completed_at: 1.day.ago
    )
    keeper_progress = ReadingProgress.create!(
      person: keeper,
      study_unit: unit,
      reference: "Alma 32",
      status: "opened"
    )
    ReadingProgress.create!(
      person: source,
      study_unit: unit,
      reference: "Alma 32",
      status: "completed",
      completed_at: 1.day.ago
    )
    other_reading = ReadingProgress.create!(
      person: source,
      study_unit: unit,
      reference: "Alma 33",
      status: "opened"
    )

    People::Merge.call(keeper:, source:)

    assert_equal keeper, study_run.reload.person
    assert_equal "completed", keeper_progress.reload.status
    assert_equal keeper, other_reading.reload.person
    assert_equal 2, keeper.reading_progresses.where(study_unit: unit).count
    assert_not Person.exists?(source.id)
  end

  test "collapses a self-duel between merged profiles and preserves its invitation history" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    invitation = DuelInvitation.create!(
      challenger_person: source, recipient_person: keeper,
      challenger_score: 92, token_digest: SecureRandom.hex(32),
      status: "open", expires_at: 1.week.from_now
    )
    duel = Quizzes::DuelInvitationClaim.call(invitation:, person: keeper).duel
    duel.update!(status: "resolved", opponent_score: 88, resolved_at: Time.current)
    event = ViralEvent.create!(
      street_duel: duel,
      duel_invitation: invitation,
      person: source,
      name: "invite_share_handoff",
      device_digest: "duplicate-carmens-share"
    )

    People::Merge.call(keeper:, source:)

    assert_not StreetDuel.exists?(duel.id)
    assert invitation.reload.revoked?
    assert_nil invitation.recipient_person
    assert_equal keeper, invitation.challenger_person
    assert_equal keeper, event.reload.person
    assert_nil event.street_duel
  end

  test "combines profile scripture highlights and removes exact duplicates" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    shared_range = {
      reference: "ot/1-sam/16", locale: "fr",
      start_verse: 1, end_verse: 2, start_offset: 2, end_offset: 14
    }
    keeper_highlight = keeper.scripture_highlights.create!(shared_range)
    source.scripture_highlights.create!(shared_range.merge(selected_text: "Le Seigneur regarde au cœur"))
    source.scripture_highlights.create!(
      reference: "ot/1-sam/16", locale: "fr",
      start_verse: 13, end_verse: 13, start_offset: 0, end_offset: 20
    )

    People::Merge.call(keeper:, source:)

    assert_equal 2, keeper.scripture_highlights.reload.count
    assert_equal [ [ 1, 2 ], [ 13, 13 ] ], keeper.scripture_highlights.order(:start_verse).pluck(:start_verse, :end_verse)
    assert_equal "Le Seigneur regarde au cœur", keeper_highlight.reload.selected_text
    assert_not Person.exists?(source.id)
  end

  test "preserves reader preferences progress and the complete annotation library" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    reference = "ot/ps/52"
    keeper.create_scripture_reader_preference!(font_scale: 90, updated_at: 3.days.ago)
    source.create_scripture_reader_preference!(
      font_scale: 130,
      line_height_key: "ample",
      measure_key: "focused",
      font_family_key: "accessible",
      background_key: "soft",
      illustrations_enabled: false,
      updated_at: 1.day.ago
    )
    keeper_progress = keeper.scripture_reading_progresses.create!(
      reference:, locale: "fr", first_opened_at: 5.days.ago,
      last_opened_at: 3.days.ago, last_verse: 3, progress_ratio: 0.3
    )
    source.scripture_reading_progresses.create!(
      reference:, locale: "fr", first_opened_at: 4.days.ago,
      last_opened_at: 1.day.ago, last_verse: 9, last_offset: 12,
      progress_ratio: 1, completed_at: 1.day.ago
    )
    keeper_tag = keeper.scripture_tags.create!(name: "Promesse")
    source_tag = source.scripture_tags.create!(name: "promesse")
    source_notebook = source.scripture_notebooks.create!(title: "Prières")
    source_mark = source.scripture_marks.create!(
      reference:, locale: "fr", anchor_scope: "passage",
      start_verse: 8, start_offset: 0, end_verse: 8, end_offset: 24,
      selected_text: "Mais moi, je suis comme un olivier verdoyant",
      visual_style: "underline", color_key: "sage", note_body: "À relire demain."
    )
    source_mark.scripture_mark_taggings.create!(scripture_tag: source_tag)
    source_notebook.scripture_notebook_entries.create!(scripture_mark: source_mark)
    source_mark.scripture_mark_links.create!(target_reference: "ot/ps/51", target_locale: "fr")

    People::Merge.call(keeper:, source:)

    preference = keeper.scripture_reader_preference.reload
    assert_equal 130, preference.font_scale
    assert_equal "ample", preference.line_height_key
    assert_not preference.illustrations_enabled?
    assert_equal 5.days.ago.to_date, keeper_progress.reload.first_opened_at.to_date
    assert_equal 9, keeper_progress.last_verse
    assert_equal 1.to_d, keeper_progress.progress_ratio
    assert keeper_progress.completed_at.present?
    assert_equal keeper, source_mark.reload.person
    assert_equal [ keeper_tag.id ], source_mark.scripture_tags.pluck(:id)
    assert_equal [ "Prières" ], source_mark.scripture_notebooks.pluck(:title)
    assert_equal [ "ot/ps/51" ], source_mark.scripture_mark_links.pluck(:target_reference)
    assert_not Person.exists?(source.id)
  end

  test "deduplicates conversation votes and keeps the newest direction" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    author = people(:pili)
    keeper.ward.update!(scripture_circle_mode: "active")
    root = ScriptureCircles::Publish.call(
      person: author,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Comment méditer cette parole ensemble ?" }
    )
    keeper_vote = ScriptureCircleConversationVote.create!(
      conversation_root: root, ward: root.ward, voter_person: keeper, direction: "up"
    )
    source_vote = ScriptureCircleConversationVote.create!(
      conversation_root: root, ward: root.ward, voter_person: source, direction: "down"
    )
    keeper_vote.update_columns(updated_at: 2.days.ago)
    source_vote.update_columns(updated_at: 1.day.ago)

    People::Merge.call(keeper:, source:)

    votes = ScriptureCircleConversationVote.where(conversation_root: root)
    assert_equal 1, votes.count
    assert_equal [ [ keeper.id, "down" ] ], votes.pluck(:voter_person_id, :direction)
    assert_not Person.exists?(source.id)
  end

  test "removes conversation votes that would become self votes during a merge" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    keeper.ward.update!(scripture_circle_mode: "active")
    source_root = ScriptureCircles::Publish.call(
      person: source,
      reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Cette réflexion appartient au profil source." }
    )
    keeper_root = ScriptureCircles::Publish.call(
      person: keeper,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Cette question appartient au profil gardé." }
    )
    ScriptureCircleConversationVote.create!(
      conversation_root: source_root, ward: keeper.ward, voter_person: keeper, direction: "up"
    )
    ScriptureCircleConversationVote.create!(
      conversation_root: keeper_root, ward: keeper.ward, voter_person: source, direction: "down"
    )

    People::Merge.call(keeper:, source:)

    assert_empty ScriptureCircleConversationVote.where(conversation_root_id: [ source_root.id, keeper_root.id ])
  end

  test "merges notification consent subscriptions prompts and delivery history" do
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    source_device = source.person_devices.create!(device_token: "lopez-push-phone")
    source_preference = source.create_notification_preference!(
      verses_enabled: true, verses_enabled_at: 1.day.ago,
      verse_frequency: "daily", verse_local_time: "07:30"
    )
    prompt = source_device.notification_prompt_states.create!(
      category: "verses", last_result: "dismissed",
      last_offered_at: 1.day.ago, snoozed_until: 29.days.from_now,
      offer_context: "study_completed"
    )
    subscription = Notifications::Subscribe.call(
      person: source, device_token: source_device.device_token,
      subscription: {
        endpoint: "https://push.example.test/merge-source",
        keys: { p256dh: "merge-p256dh", auth: "merge-auth" }
      },
      locale: :fr, time_zone: "Europe/Paris"
    )
    delivery = NotificationDelivery.create!(
      web_push_subscription: subscription, person: source,
      kind: "daily_verse", dedupe_key: "merge-notification-history",
      destination: "/fr/bible/genese/1", status: "sent", sent_at: 1.hour.ago
    )

    People::Merge.call(keeper:, source:)

    assert keeper.notification_preference.reload.challenges_enabled?
    assert keeper.notification_preference.verses_enabled?
    assert_equal source_preference.verse_frequency, keeper.notification_preference.verse_frequency
    assert_equal keeper, subscription.reload.person
    assert_equal keeper, delivery.reload.person
    assert_equal keeper, prompt.reload.person_device.person
    assert_not Person.exists?(source.id)
  end

  test "refuses to merge fichas from another rama" do
    error = assert_raises(People::Error) do
      People::Merge.call(keeper: people(:pili), source: wards(:blank).people.create!(
        given_name: "Pili",
        avatar_key: "gato",
        favorite_year: 2001
      ))
    end
    assert_equal :ward, error.code
  end


  private

    def create_study
      program = StudyProgram.create!(
        slug: "merge-test",
        title: "Merge test",
        year: 2025,
        canon: "book_of_mormon",
        locale: "es",
        status: "published",
        source_url: "https://example.test/merge"
      )
      unit = program.study_units.create!(
        slug: "merge-week",
        kind: "week",
        position: 1,
        title: "Alma 32–33",
        source_url: "https://example.test/merge/week",
        status: "published"
      )
      content = YAML.safe_load_file(
        Rails.root.join("config/study/come_follow_me_2026.yml")
      ).dig("quizzes", 0, "content")
      quiz = unit.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json)
      )
      [ unit, quiz ]
    end
end
