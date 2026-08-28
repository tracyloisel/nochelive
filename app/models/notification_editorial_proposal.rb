class NotificationEditorialProposal < ApplicationRecord
  class ApprovalError < StandardError; end

  PROPOSAL_TYPES = %w[message verse].freeze
  STATUSES = %w[draft approved].freeze
  APPROVAL_LIFETIME = 15.minutes
  LOCALES = %w[es pt-BR fr en].freeze
  MESSAGE_KINDS = %w[
    daily_verse study_reading duel_invitation duel_reminder
    duel_result_won duel_result_finished duel_result_tie
    night_tomorrow night_starting_soon
  ].freeze
  PLACEHOLDERS = {
    "daily_verse" => %w[reference],
    "study_reading" => %w[title],
    "duel_invitation" => %w[name pack],
    "duel_reminder" => %w[name pack],
    "duel_result_won" => %w[name pack],
    "duel_result_finished" => %w[name pack],
    "duel_result_tie" => %w[name pack],
    "night_tomorrow" => %w[time],
    "night_starting_soon" => %w[time]
  }.freeze

  validates :editorial_key, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9][a-z0-9._:-]*\z/ }
  validates :proposal_type, inclusion: { in: PROPOSAL_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validate :validate_payload

  scope :ordered, -> { order(:proposal_type, :editorial_key) }

  def approved? = status == "approved"

  def content_digest
    Digest::SHA256.hexdigest(JSON.generate(canonical(payload.deep_stringify_keys)))
  end

  def issue_approval!
    raise ApprovalError, errors.full_messages.to_sentence unless valid?
    raise ApprovalError, "Approved proposals are immutable" if approved?

    token = SecureRandom.urlsafe_base64(32)
    update!(
      approval_token_digest: token_digest(token),
      approval_content_digest: content_digest,
      approval_expires_at: APPROVAL_LIFETIME.from_now
    )
    token
  end

  def approve!(token)
    with_lock do
      raise ApprovalError, "Approved proposals are immutable" if approved?
      raise ApprovalError, "Invalid or expired approval confirmation" unless approval_valid?(token)
      raise ApprovalError, "Proposal changed after approval preview" unless approval_content_digest == content_digest

      update!(
        status: "approved",
        approved_at: Time.current,
        approval_token_digest: nil,
        approval_content_digest: nil,
        approval_expires_at: nil
      )
    end
  end

  def invalidate_approval!
    self.approval_token_digest = nil
    self.approval_content_digest = nil
    self.approval_expires_at = nil
  end

  private

    def validate_payload
      case proposal_type
      when "message" then validate_message_payload
      when "verse" then validate_verse_payload
      end
    end

    def validate_message_payload
      kind = payload["notification_kind"].to_s
      errors.add(:payload, "notification_kind is invalid") unless MESSAGE_KINDS.include?(kind)
      translations = payload["translations"]
      unless translations.is_a?(Hash) && translations.keys.map(&:to_s).sort == LOCALES.sort
        errors.add(:payload, "must contain exactly es, pt-BR, fr, and en translations")
        return
      end

      expected = PLACEHOLDERS.fetch(kind, [])
      translations.each do |locale, copy|
        title = copy.is_a?(Hash) ? copy["title"].to_s.strip : ""
        body = copy.is_a?(Hash) ? copy["body"].to_s.strip : ""
        errors.add(:payload, "#{locale} title is required") if title.blank?
        errors.add(:payload, "#{locale} body is required") if body.blank?
        errors.add(:payload, "#{locale} title is too long") if title.length > 80
        errors.add(:payload, "#{locale} body is too long") if body.length > 180
        actual = body.scan(/%\{([a-z_]+)\}/).flatten.uniq.sort
        errors.add(:payload, "#{locale} placeholders must be #{expected.join(', ')}") unless actual == expected.sort
      end
    end

    def validate_verse_payload
      Date.iso8601(payload.fetch("publish_on").to_s)
      study = payload.fetch("study").to_s
      verse = Integer(payload.fetch("verse"))
      theme = payload.fetch("theme").to_s.strip
      errors.add(:payload, "study is required") if study.blank?
      errors.add(:payload, "theme is required") if theme.blank?
      entry = Notifications::VerseCatalog::Entry.new(id: editorial_key, study:, verse:, theme:)
      LOCALES.each { |locale| entry.destination(locale) }
    rescue KeyError, ArgumentError, TypeError, ActiveRecord::RecordNotFound => error
      errors.add(:payload, "verse is invalid: #{error.message}")
    end

    def approval_valid?(token)
      token.present? && approval_token_digest.present? && approval_expires_at&.future? &&
        ActiveSupport::SecurityUtils.secure_compare(approval_token_digest, token_digest(token))
    end

    def token_digest(token)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.key_generator.generate_key("notification-editorial-approval", 32), token.to_s)
    end

    def canonical(value)
      case value
      when Hash then value.keys.sort.to_h { |key| [ key, canonical(value[key]) ] }
      when Array then value.map { |item| canonical(item) }
      else value
      end
    end
end
