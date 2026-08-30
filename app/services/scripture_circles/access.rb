module ScriptureCircles
  class Access
    Error = Class.new(StandardError)
    MissingIdentity = Class.new(Error)
    MissingWard = Class.new(Error)
    Disabled = Class.new(Error)

    attr_reader :person, :ward

    def initialize(person:)
      @person = person or raise MissingIdentity
      @ward = person.ward or raise MissingWard
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
      return scope.first unless create

      scope.first || ward.scripture_circle_threads.create!(reference: reference.to_s)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => error
      # A concurrent first publication may create the same ward/chapter thread between
      # the lookup and insert. The unique database index remains authoritative; reuse
      # the thread when it now exists, but never mask a genuinely invalid reference.
      scope.first || raise(error)
    end

    def post!(id, write: false)
      write ? writable! : readable!
      ward.scripture_circle_posts.find(id)
    end

    def proposal!(id, write: false)
      write ? writable! : readable!
      ScriptureCircleModerationProposal.where(ward_id: ward.id).find(id)
    end
  end
end
