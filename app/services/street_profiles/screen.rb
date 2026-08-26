module StreetProfiles
  class Screen
    Result = Struct.new(:name, :person, :people, keyword_init: true)

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(people_on_device:, current_person: nil, fresh: false, not_me: false,
                   claim_person: nil, homonyms: false, needs_family: false)
      @people_on_device = Array(people_on_device)
      @current_person = current_person
      @fresh = fresh
      @not_me = not_me
      @claim_person = claim_person
      @homonyms = homonyms
      @needs_family = needs_family
    end

    def call
      return result(:claim, person: @claim_person) if @claim_person
      return result(:homonyms) if @homonyms
      return result(:form) if @needs_family || @fresh
      return result(:welcome, person: @current_person, people: [ @current_person ]) if @current_person && !@not_me

      remaining = remaining_people
      if remaining.one? && @current_person.nil?
        return result(:welcome, person: remaining.first, people: remaining)
      end
      return result(:device, people: remaining) if remaining.any?

      result(:form)
    end

    private

      def remaining_people
        skip_id = @current_person&.id if @not_me
        @people_on_device.reject { |person| person.id == skip_id }
      end

      def result(name, person: nil, people: [])
        Result.new(name:, person:, people:)
      end
  end
end
