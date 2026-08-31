module AdminApi
  class WardEventsController < BaseController
    before_action :set_ward
    before_action :set_ward_event, only: %i[show update publish cancel]

    def index
      events = @ward.ward_events.order(starts_at: :desc, id: :desc)
      events = events.where(status: requested_status) if params[:status].present?
      render json: { events: events.map { |event| ward_event_json(event) } }
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    def show
      render json: { event: ward_event_json(@ward_event, audits: true) }
    end

    def create
      event = WardEvent.create_draft!(ward: @ward, attributes: ward_event_attributes, actor: admin_audit_actor)
      admin_audit!("create_ward_event", ward_id: @ward.id, ward_event_id: event.id)
      render json: { event: ward_event_json(event, audits: true) }, status: :created
    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      render json: { error: error_message(error) }, status: :unprocessable_entity
    end

    def update
      @ward_event.update_draft!(attributes: ward_event_attributes, actor: admin_audit_actor)
      admin_audit!("update_ward_event", ward_id: @ward.id, ward_event_id: @ward_event.id)
      render json: { event: ward_event_json(@ward_event, audits: true) }
    rescue ActiveRecord::RecordInvalid, WardEvent::TransitionError, ArgumentError => error
      render json: { error: error_message(error) }, status: :unprocessable_entity
    end

    def publish
      @ward_event.publish!(actor: admin_audit_actor)
      admin_audit!("publish_ward_event", ward_id: @ward.id, ward_event_id: @ward_event.id)
      render json: { event: ward_event_json(@ward_event, audits: true) }
    rescue ActiveRecord::RecordInvalid, WardEvent::TransitionError, ArgumentError => error
      render json: { error: error_message(error) }, status: :unprocessable_entity
    end

    def cancel
      @ward_event.cancel!(actor: admin_audit_actor, reason: params[:reason])
      admin_audit!("cancel_ward_event", ward_id: @ward.id, ward_event_id: @ward_event.id)
      render json: { event: ward_event_json(@ward_event, audits: true) }
    rescue ActiveRecord::RecordInvalid, WardEvent::TransitionError, ArgumentError => error
      render json: { error: error_message(error) }, status: :unprocessable_entity
    end

    private

      def set_ward
        @ward = Ward.find_by!(code: Ward.normalize_code(params[:ward_code]))
      end

      def set_ward_event
        @ward_event = @ward.ward_events.find(params[:id])
      end

      def requested_status
        value = params[:status].to_s
        raise ArgumentError, "status is invalid" unless WardEvent::STATUSES.include?(value)

        value
      end

      def ward_event_attributes
        params.permit(
          :kind, :title, :summary, :starts_at, :ends_at, :location_label,
          :destination_path, :destination_url, :artwork_path
        ).to_h
      end

      def ward_event_json(event, audits: false)
        payload = {
          id: event.id,
          ward: { id: event.ward_id, code: @ward.code, name: @ward.name },
          kind: event.kind,
          title: event.title,
          summary: event.summary,
          starts_at: event.starts_at.iso8601,
          ends_at: event.ends_at.iso8601,
          location_label: event.location_label,
          destination: {
            type: event.external_destination? ? "external" : "internal",
            value: event.destination
          },
          artwork_path: event.artwork_path,
          status: event.status,
          approved_by: event.approved_by,
          approved_at: event.approved_at&.iso8601,
          cancelled_by: event.cancelled_by,
          cancelled_at: event.cancelled_at&.iso8601,
          cancellation_reason: event.cancellation_reason,
          created_at: event.created_at.iso8601,
          updated_at: event.updated_at.iso8601
        }
        payload[:audit] = event.ward_event_audits.order(:created_at, :id).map { |audit| audit_json(audit) } if audits
        payload
      end

      def audit_json(audit)
        {
          action: audit.action,
          actor: audit.actor_label,
          metadata: audit.metadata,
          created_at: audit.created_at.iso8601
        }
      end

      def error_message(error)
        error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : error.message
      end
  end
end
