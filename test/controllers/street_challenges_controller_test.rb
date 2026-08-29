require "test_helper"

class StreetChallengesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect! while response.redirect?
  end

  test "challenge page leads with the next pack, points, and compact social sections" do
    incoming = DuelInvitation.create!(
      challenger_person: people(:carmen_garcia), recipient_person: people(:pili),
      challenger_score: 61, token_digest: SecureRandom.hex(32), status: "open",
      expires_at: 7.days.from_now
    )

    get street_challenges_path

    assert_response :success
    assert_select "body.is-duel-campus.is-celestial-dark"
    assert_select ".duel-campus-world-picture img[src=?]", generated_media_src("media/social/campus-scriptures-celestial-dark-v1.png")
    assert_select ".duel-campus-world-art > span", count: 0
    assert_select ".duel-campus-hero-art", count: 0
    assert_select "img[src^='/media/ui/duel-campus/']", count: 0
    %w[crown duel-books duel-scrolls duel-staffs book].each { |icon| assert_select ".picto-#{icon}" }
    assert_select "h1", text: I18n.t("duel_campus.title")
    assert_select ".quiz-hud-score", text: /#{Quizzes::Complete.total_best(people(:pili))}/
    assert_select ".duel-campus-counts .is-active dd", text: I18n.t("duel_campus.counts.active", count: 0)
    assert_select ".duel-campus-counts .is-incoming dd", text: I18n.t("duel_campus.counts.incoming", count: 1)
    assert_select ".duel-campus-priority" do
      assert_select "h2", text: QuizDefinition.catalog.find_pack("coronas").copy(:title)
      assert_select ".duel-campus-priority-meta", text: /89/
      assert_select ".duel-campus-priority-action", text: I18n.t("duel_campus.actions.play_pack")
      assert_select ".duel-campus-priority-action.duel-campus-command"
    end
    assert_select ".duel-campus-section.is-incoming" do
      assert_select "time.duel-campus-invitation-date[datetime=?]", incoming.expires_at.iso8601,
        text: /#{Regexp.escape(I18n.l(incoming.expires_at.to_date))}/
      assert_select ".duel-campus-card-actions .duel-campus-command", text: I18n.t("duel_campus.actions.accept")
    end
    assert_select ".duel-campus-section.is-active", count: 0
    assert_select "#inviter.duel-campus-section.is-friends"
    assert_select ".duel-campus-card.is-receipt.is-external" do
      assert_select ".duel-campus-share-mark", text: "↗"
      assert_select "h3", text: I18n.t("duel_campus.labels.shared_link")
      assert_select ".duel-campus-receipt strong", text: I18n.t("duel_campus.receipts.external.ready")
      assert_select "h3", text: I18n.t("duel_campus.labels.friend"), count: 0
      assert_select "time.duel-campus-invitation-date", text: /#{Regexp.escape(I18n.l(duel_invitations(:open_pili_invitation).created_at.to_date))}/
    end
  end

  test "rival picker names the pack a live rival is playing" do
    run = quiz_runs(:carmen_milagros)
    run.update!(status: "open", position: 6, score: 41)
    Presences::Registry.enter(connection_id: "test:carmen", person_id: people(:carmen_garcia).id, role: "street")

    get street_challenges_path

    assert_response :success
    assert_select ".duel-campus-friends small.is-live", text: /#{Regexp.escape(run.pack.copy(:title))}/
    assert_select ".duel-campus-friends small.is-live", text: %r{6/10}
  ensure
    Presences::Registry.reset!
  end

  test "an available rival uses the whole chip as the invitation button" do
    get street_challenges_path

    assert_response :success
    assert_select ".duel-campus-friends form.duel-campus-friend-form[action=?][method=?]", street_challenges_path, "post", minimum: 1 do
      assert_select "button.duel-campus-friend.duel-campus-friend-invite[type=submit]", minimum: 1 do
        assert_select ".duel-campus-friend-copy", minimum: 1
        assert_select ".duel-campus-friend-cta", text: /#{Regexp.escape(I18n.t("duel_campus.actions.invite"))}/
      end
    end
  end

  test "active challenge reads as a points race with the rivals open pack" do
    carmen = people(:carmen_garcia)
    invitation = DuelInvitation.create!(
      challenger_person: people(:pili), recipient_person: carmen,
      token_digest: SecureRandom.hex(32), status: "claimed", claimed_by_person: carmen,
      claimed_at: 10.minutes.ago, expires_at: 7.days.from_now
    )
    duel = StreetDuel.create!(
      challenger_person: people(:pili), opponent_person: carmen,
      status: "active", accepted_at: 10.minutes.ago, expires_at: 7.days.from_now,
      origin_invitation: invitation
    )
    invitation.update!(street_duel: duel)
    run = quiz_runs(:carmen_milagros)
    run.update!(status: "open", position: 6, score: 41, opened_at: 5.minutes.ago)
    Presences::Registry.enter(connection_id: "test:carmen-active", person_id: carmen.id, role: "street")

    get street_challenges_path

    assert_response :success
    assert_select ".duel-campus-section.is-active"
    assert_select ".duel-campus-card.is-duel.is-ready" do
      assert_select ".duel-campus-live", text: I18n.t("duel_campus.states.live")
      assert_select ".duel-campus-race-readout", text: /#{Regexp.escape(run.pack.copy(:title))}/
      assert_select ".duel-campus-card-status", text: %r{6/10}
    end
    assert_select "body", text: /Translation missing/, count: 0
  ensure
    Presences::Registry.reset!
  end

  test "an accepted invitation link shows the person who claimed it" do
    invitation = duel_invitations(:open_pili_invitation)
    invitation.update!(
      status: "claimed",
      claimed_by_person: people(:carmen_garcia),
      claimed_at: Time.current
    )

    get street_challenges_path

    assert_response :success
    assert_select "#duel_invitation_receipt_#{invitation.id}" do
      assert_select "strong", text: I18n.t("duel_campus.receipts.claimed", name: people(:carmen_garcia).display_name)
    end
  end

  test "creates a shareable invitation from a completed raw score" do
    assert_difference("DuelInvitation.count", 1) do
      post street_challenges_path, params: { run_id: quiz_runs(:pili_coronas).id }, as: :json
    end

    assert_response :created
    payload = JSON.parse(response.body)
    invitation = DuelInvitation.find(payload.fetch("invitation_id"))
    assert_equal 95, invitation.challenger_score
    assert_equal invitation, DuelInvitation.find_by_token(payload.fetch("token"))
    assert_match %r{/desafio/}, payload.fetch("url")
  end

  test "invitation page uses the friendship composition and does not record a human open on GET" do
    invitation = duel_invitations(:open_pili_invitation)
    token = invitation.public_token

    assert_no_changes -> { invitation.reload.human_opened_at } do
      get street_challenge_path(token)
    end

    assert_response :success
    assert_select "body.is-duel-invitation"
    assert_select "img[src=?]", generated_media_src("media/social/campus-invitation-friends-v1.png")
    assert_select ".picto-duel-scrolls"
    assert_select "time.duel-campus-invitation-date[datetime=?]", invitation.expires_at.iso8601,
      text: /#{Regexp.escape(I18n.l(invitation.expires_at.to_date))}/
  end

  test "a rematch endpoint creates an invitation without selecting a pack" do
    duel = street_duels(:pili_vs_carmen)

    assert_difference("DuelInvitation.count", 1) do
      post street_duel_rematch_path(duel)
    end

    invitation = DuelInvitation.order(:id).last
    assert_equal duel, invitation.rematch_of_duel
    assert_not invitation.attributes.key?("pack_id")
  end

  test "a waiting duel names both paths and turns the score into anticipation" do
    pili = people(:pili)
    rival = people(:carmen_lopez)
    invitation = DuelInvitation.create!(
      challenger_person: pili, recipient_person: rival,
      token_digest: SecureRandom.hex(32), status: "claimed", claimed_by_person: rival,
      claimed_at: 10.minutes.ago, expires_at: 7.days.from_now
    )
    run = QuizRun.create!(
      person: pili, device_digest: Digest::SHA256.hexdigest("duel-detail-controller"),
      pack_id: "coronas", position: 10, score: 95, status: "finished", opened_at: 20.minutes.ago
    )
    duel = StreetDuel.create!(
      challenger_person: pili, opponent_person: rival,
      challenger_run: run, challenger_score: 95,
      origin_invitation: invitation, status: "one_scored",
      accepted_at: 10.minutes.ago, expires_at: 7.days.from_now
    )
    invitation.update!(street_duel: duel)

    get street_duel_path(duel)

    assert_response :success
    assert_select "body.is-duel-detail"
    assert_select "main main", count: 0
    assert_select ".duel-detail-world picture img[alt='']"
    assert_select ".duel-detail-sheet[aria-labelledby='duel_detail_status']"
    assert_select ".duel-detail-player.is-me" do
      assert_select "small", text: run.pack.copy(:title)
      assert_select ".duel-detail-score", text: /95.*#{Regexp.escape(I18n.t("duel_campus.counts.crowns"))}/m
    end
    assert_select ".duel-detail-player.is-rival small", text: I18n.t("duel_campus.copy.pack_waiting")
    assert_select ".duel-detail-versus", text: I18n.t("duel_campus.labels.versus")
    assert_select ".duel-detail-status.is-waiting" do
      assert_select ".duel-detail-status-kicker", text: I18n.t("duel_campus.priority.score_set")
      assert_select "h2#duel_detail_status", text: I18n.t("duel_campus.states.waiting")
      assert_select "p", text: I18n.t("duel_campus.priority.waiting", score: 95, name: rival.given_name)
    end
    assert_select ".duel-detail-actions .btn[href=?]", jugar_path, text: I18n.t("duel_campus.actions.play_any_pack")
    assert_select ".duel-detail-actions .quiet-link[href=?]", street_challenges_path, text: I18n.t("duel_campus.actions.back_campus")
  end

  test "replaying an already completed acceptance opens the duel without creating a throwaway run" do
    carmen = people(:carmen_garcia)
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect! while response.redirect?
    invitation = duel_invitations(:resolved_pili_invitation)

    assert_no_difference("QuizRun.count") do
      post street_challenge_accept_path(invitation.public_token)
    end

    assert_redirected_to street_duel_path(street_duels(:pili_vs_carmen))
  end
end
