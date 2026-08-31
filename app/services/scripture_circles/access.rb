module ScriptureCircles
  class Access
    Error = Class.new(StandardError)
    MissingIdentity = Class.new(Error)
    MissingWard = Class.new(Error)
    Disabled = Class.new(Error)
    ArchivedThread = Class.new(Error)

    attr_reader :person, :ward

    def initialize(person:)
      @person = person or raise MissingIdentity
      # Resolve by the persisted foreign key instead of trusting a possibly
      # cached Person#ward association. Circle availability is a current ward
      # policy and may change while a person object remains in memory.
      @ward = Ward.find_by(id: person.ward_id) or raise MissingWard
    end

    def readable!
      raise Disabled unless ward.scripture_circle_readable?
      self
    end

    def writable!
      raise Disabled unless ward.scripture_circle_active?
      self
    end

    def thread_for(reference:, create: false)
      create ? writable! : readable!
      scope = ward.scripture_circle_threads.where(reference: reference.to_s)
      thread = scope.first
      return thread if !create && thread&.status == "active"
      return nil unless create
      return thread if thread&.status == "active"
      raise ArchivedThread if thread

      ward.scripture_circle_threads.create!(reference: reference.to_s)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => error
      # A concurrent first publication may create the same ward/chapter thread between
      # the lookup and insert. The unique database index remains authoritative; reuse
      # the thread when it now exists, but never mask a genuinely invalid reference.
      thread = scope.first
      raise ArchivedThread if thread&.status == "archived"

      thread || raise(error)
    end

    def post!(id, write: false)
      write ? writable! : readable!
      post = ward.scripture_circle_posts.includes(:scripture_circle_thread).find(id)
      raise ArchivedThread unless post.scripture_circle_thread&.status == "active"

      post
    end

    def proposal!(id, write: false)
      write ? writable! : readable!
      proposal = ScriptureCircleModerationProposal
        .where(ward_id: ward.id)
        .includes(scripture_circle_post: :scripture_circle_thread)
        .find(id)
      raise ArchivedThread unless proposal.scripture_circle_post.scripture_circle_thread&.status == "active"

      proposal
    end
  end
end
