module AdminApi
  class NotificationEditorialsController < BaseController
    before_action :set_proposal, only: %i[update preview approval_preview approve]

    def index
      proposals = NotificationEditorialProposal.ordered
      proposals = proposals.where(status: params[:status]) if params[:status].present?
      proposals = proposals.where(proposal_type: params[:proposal_type]) if params[:proposal_type].present?
      render json: { proposals: proposals.map { |proposal| proposal_json(proposal) } }
    end

    def create
      proposal = NotificationEditorialProposal.create!(proposal_attributes)
      admin_audit!("create_notification_editorial", proposal_id: proposal.id, editorial_key: proposal.editorial_key)
      render json: { proposal: proposal_json(proposal) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end

    def update
      raise NotificationEditorialProposal::ApprovalError, "Approved proposals are immutable" if @proposal.approved?

      @proposal.assign_attributes(proposal_attributes.except(:editorial_key, :proposal_type))
      @proposal.invalidate_approval!
      @proposal.save!
      admin_audit!("update_notification_editorial", proposal_id: @proposal.id, editorial_key: @proposal.editorial_key)
      render json: { proposal: proposal_json(@proposal) }
    rescue ActiveRecord::RecordInvalid, NotificationEditorialProposal::ApprovalError => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    def preview
      render json: {
        proposal: proposal_json(@proposal),
        preview: Notifications::EditorialPreview.call(@proposal),
        delivery_enabled: false
      }
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end

    def approval_preview
      confirmation = @proposal.issue_approval!
      render json: {
        approval: {
          proposal: proposal_json(@proposal),
          preview: Notifications::EditorialPreview.call(@proposal),
          content_digest: @proposal.approval_content_digest,
          expires_at: @proposal.approval_expires_at.iso8601,
          effect: "Approves this exact immutable proposal. It does not enable or send notifications."
        },
        confirmation:
      }
    rescue ActiveRecord::RecordInvalid, NotificationEditorialProposal::ApprovalError => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    def approve
      @proposal.approve!(params[:confirmation])
      admin_audit!("approve_notification_editorial", proposal_id: @proposal.id, editorial_key: @proposal.editorial_key)
      render json: { approved: true, proposal: proposal_json(@proposal), delivery_enabled: false }
    rescue NotificationEditorialProposal::ApprovalError => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    private

      def set_proposal
        @proposal = NotificationEditorialProposal.find(params[:id])
      end

      def proposal_attributes
        params.permit(:editorial_key, :proposal_type, payload: {}).to_h
      end

      def proposal_json(proposal)
        {
          id: proposal.id,
          editorial_key: proposal.editorial_key,
          proposal_type: proposal.proposal_type,
          payload: proposal.payload,
          status: proposal.status,
          approved_at: proposal.approved_at&.iso8601,
          content_digest: proposal.content_digest,
          created_at: proposal.created_at.iso8601,
          updated_at: proposal.updated_at.iso8601
        }
      end
  end
end
