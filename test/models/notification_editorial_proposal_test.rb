require "test_helper"

class NotificationEditorialProposalTest < ActiveSupport::TestCase
  test "requires native copy in all four locales with exact placeholders" do
    proposal = NotificationEditorialProposal.new(
      editorial_key: "message.daily-verse.v1",
      proposal_type: "message",
      payload: {
        "notification_kind" => "daily_verse",
        "translations" => translations("Une lumière", "%{reference} est ouvert pour toi.")
      }
    )

    assert proposal.valid?

    proposal.payload["translations"]["en"]["body"] = "A passage is ready."
    assert_not proposal.valid?
    assert_includes proposal.errors[:payload].join, "en placeholders"
  end

  test "duel copy names the friend without binding the invitation to a pack" do
    proposal = NotificationEditorialProposal.new(
      editorial_key: "message.duel-invitation.v1",
      proposal_type: "message",
      payload: {
        "notification_kind" => "duel_invitation",
        "translations" => translations("Une invitation du Campus", "%{name} aimerait apprendre avec toi.")
      }
    )

    assert proposal.valid?

    proposal.payload["translations"]["fr"]["body"] = "%{name} t'attend sur %{pack}."
    assert_not proposal.valid?
    assert_includes proposal.errors[:payload].join, "fr placeholders"
  end

  test "approval is exact short-lived and single use" do
    proposal = create_message_proposal
    token = proposal.issue_approval!

    proposal.approve!(token)

    assert proposal.approved?
    assert proposal.approved_at.present?
    assert_raises(NotificationEditorialProposal::ApprovalError) { proposal.approve!(token) }
  end

  test "editing after preview invalidates the exact approval" do
    proposal = create_message_proposal
    token = proposal.issue_approval!
    proposal.payload["translations"]["fr"]["title"] = "Une parole pour aujourd’hui"
    proposal.save!

    assert_raises(NotificationEditorialProposal::ApprovalError) { proposal.approve!(token) }
  end

  test "validates and previews a canonical dated verse" do
    proposal = NotificationEditorialProposal.create!(
      editorial_key: "verse.2026-09-01",
      proposal_type: "verse",
      payload: {
        "publish_on" => "2026-09-01",
        "study" => "nt/john/3",
        "verse" => 16,
        "theme" => "love"
      }
    )

    preview = Notifications::EditorialPreview.call(proposal)

    assert_equal "2026-09-01", preview.fetch(:publish_on)
    assert_equal NotificationEditorialProposal::LOCALES.sort, preview.fetch(:locales).keys.sort
    assert preview.dig(:locales, "fr", :citation).present?
    assert_match %r{\A/fr/}, preview.dig(:locales, "fr", :destination)
  end

  private

    def create_message_proposal
      NotificationEditorialProposal.create!(
        editorial_key: "message.daily-verse.v1",
        proposal_type: "message",
        payload: {
          "notification_kind" => "daily_verse",
          "translations" => translations("Une lumière", "%{reference} est ouvert pour toi.")
        }
      )
    end

    def translations(title, body)
      NotificationEditorialProposal::LOCALES.to_h do |locale|
        [ locale, { "title" => "#{title} #{locale}", "body" => body } ]
      end
    end
end
