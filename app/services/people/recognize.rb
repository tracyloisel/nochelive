module People
  class Recognize
    Card = Struct.new(:person, :show_year, keyword_init: true)

    def self.call(ward:, given_name:)
      new(ward:, given_name:).call
    end

    def initialize(ward:, given_name:)
      @ward = ward
      @given_name = given_name
    end

    def call
      people = @ward.people.named(@given_name).includes(:last_ward_team).order(:family_name, :id).to_a
      people.map do |person|
        Card.new(person:, show_year: collide_year?(people, person))
      end
    end

    private

      def collide_year?(people, person)
        people.any? do |other|
          other.id != person.id &&
            other.avatar_key == person.avatar_key &&
            other.family_name_key == person.family_name_key
        end
      end
  end
end
