# frozen_string_literal: true

raise "The Scripture Campus demo seed is development-only" unless Rails.env.development?

module Seeds
  class DuelCampusDemo
    SOURCE = "campus_demo"
    EXPIRES_IN = 30.days

    def initialize(target:, now: Time.current.change(usec: 0))
      @target = target
      @ward = target.ward || Ward.listed.order(:id).first || Ward.order(:id).first ||
        raise(ArgumentError, "the demo needs at least one local ward for its friend profiles")
      @now = now
    end

    def call
      ApplicationRecord.transaction do
        people = seed_people
        target_run = finished_run(@target, "target-score", score: 84, pack_id: "abraham", opened_at: @now - 3.hours)

        seed_invitation(
          key: "incoming-amina", challenger: people.fetch(:amina), recipient: @target,
          score: 91, receipt: :seen, age: 8.minutes
        )
        seed_invitation(
          key: "incoming-noe", challenger: people.fetch(:noe), recipient: @target,
          score: 76, receipt: :delivered, age: 19.minutes
        )
        seed_invitation(
          key: "outgoing-lucia", challenger: @target, recipient: people.fetch(:lucia),
          score: target_run.score, run: target_run, receipt: :seen, age: 31.minutes
        )
        seed_invitation(
          key: "outgoing-elias", challenger: @target, recipient: people.fetch(:elias),
          score: target_run.score, run: target_run, receipt: :delivered, age: 47.minutes
        )
        seed_invitation(
          key: "outgoing-link", challenger: @target, recipient: nil,
          score: target_run.score, run: target_run, receipt: :opened, age: 1.hour
        )
        seed_invitation(
          key: "outgoing-ruth-declined", challenger: @target, recipient: people.fetch(:ruth),
          score: target_run.score, run: target_run, receipt: :seen, status: "declined", age: 2.hours
        )

        seed_duel(
          key: "active-your-turn", challenger: people.fetch(:samuel), opponent: @target,
          challenger_score: 93, opponent_score: nil, age: 14.minutes,
          challenger_pack: "moises", opponent_pack: "abraham"
        )
        seed_duel(
          key: "active-waiting", challenger: @target, opponent: people.fetch(:ines),
          challenger_score: 84, opponent_score: nil, age: 26.minutes,
          challenger_pack: "abraham", opponent_pack: "profetas"
        )
        seed_duel(
          key: "active-ready", challenger: @target, opponent: people.fetch(:david),
          challenger_score: nil, opponent_score: nil, age: 39.minutes,
          challenger_pack: "jehova", opponent_pack: "coronas"
        )

        seed_duel(
          key: "result-ahead", challenger: @target, opponent: people.fetch(:chloe),
          challenger_score: 88, opponent_score: 81, age: 3.hours,
          challenger_pack: "abraham", opponent_pack: "hermanas"
        )
        seed_duel(
          key: "result-behind", challenger: people.fetch(:gabriel), opponent: @target,
          challenger_score: 96, opponent_score: 89, age: 5.hours,
          challenger_pack: "nazareno", opponent_pack: "placas"
        )
        seed_duel(
          key: "result-tie", challenger: @target, opponent: people.fetch(:sara),
          challenger_score: 82, opponent_score: 82, age: 7.hours,
          challenger_pack: "premortal", opponent_pack: "coronas"
        )
        previous = seed_duel(
          key: "rematch-history", challenger: people.fetch(:lea), opponent: @target,
          challenger_score: 68, opponent_score: 65, age: 2.days,
          challenger_pack: "exaltacion", opponent_pack: "abish", seen_for_target: true
        )
        seed_duel(
          key: "active-rematch", challenger: @target, opponent: people.fetch(:lea),
          challenger_score: nil, opponent_score: nil, age: 6.minutes,
          challenger_pack: "coronas", opponent_pack: "abraham", rematch_of: previous
        )
      end

      campus = Quizzes::DuelCampus.call(person: @target)
      {
        target: @target,
        incoming: campus.incoming.size,
        active: campus.active.size,
        unseen_results: campus.counts.results,
        outgoing: campus.outgoing.size
      }
    end

    private

      def seed_people
        {
          amina: [ "Amina", "aguila", 2004 ],
          noe: [ "Noé", "colibri", 2007 ],
          lucia: [ "Lucía", "delfin", 2002 ],
          elias: [ "Élias", "perro", 2005 ],
          ruth: [ "Ruth", "oveja", 2001 ],
          samuel: [ "Samuel", "elefante", 2003 ],
          ines: [ "Inès", "tortuga", 2006 ],
          david: [ "David", "cebra", 2000 ],
          chloe: [ "Chloé", "jirafa", 2008 ],
          gabriel: [ "Gabriel", "ballena", 1999 ],
          sara: [ "Sara", "gato", 2009 ],
          lea: [ "Léa", "loro", 2004 ]
        }.transform_values do |given_name, avatar_key, favorite_year|
          person = @ward.people.find_or_initialize_by(
            given_name_key: Person.name_key(given_name),
            family_name_key: ""
          )
          person.assign_attributes(
            given_name: given_name,
            family_name: nil,
            avatar_key: avatar_key,
            favorite_year: favorite_year,
            locale: @target.locale
          )
          person.save!
          person
        end
      end

      def seed_invitation(key:, challenger:, recipient:, score:, receipt:, age:, run: nil, status: "open", rematch_of: nil)
        timestamp = @now - age
        run ||= finished_run(
          challenger,
          "invitation-#{key}",
          score: score,
          pack_id: pack_for(key),
          opened_at: timestamp - 12.minutes
        ) if score

        invitation = demo_invitation(key)
        invitation.assign_attributes(
          challenger_person: challenger,
          recipient_person: recipient,
          challenger_run: run,
          challenger_score: score,
          claimed_by_person: nil,
          rematch_of_duel: rematch_of,
          token_digest: invitation.token_digest.presence || DuelInvitation.digest("#{SOURCE}:#{@target.id}:#{key}"),
          status: status,
          source: SOURCE,
          channel: recipient ? "noche" : "link",
          share_handoff_at: receipt.in?(%i[handoff opened delivered seen]) ? timestamp : nil,
          human_opened_at: receipt == :opened ? timestamp + 2.minutes : nil,
          delivered_at: receipt.in?(%i[delivered seen]) ? timestamp + 1.minute : nil,
          seen_at: receipt == :seen ? timestamp + 3.minutes : nil,
          claimed_at: nil,
          declined_at: status == "declined" ? timestamp + 5.minutes : nil,
          expires_at: @now + EXPIRES_IN,
          metadata: { "seed_key" => scoped_key(key), "target_person_id" => @target.id }
        )
        invitation.save!
        invitation.update_columns(created_at: timestamp, updated_at: timestamp)
        invitation
      end

      def seed_duel(
        key:, challenger:, opponent:, challenger_score:, opponent_score:, age:,
        challenger_pack:, opponent_pack:, seen_for_target: false, rematch_of: nil
      )
        accepted_at = @now - age
        challenger_run = if challenger_score
          finished_run(
            challenger,
            "duel-#{key}-challenger",
            score: challenger_score,
            pack_id: challenger_pack,
            opened_at: accepted_at + 2.minutes
          )
        end
        opponent_run = if opponent_score
          finished_run(
            opponent,
            "duel-#{key}-opponent",
            score: opponent_score,
            pack_id: opponent_pack,
            opened_at: accepted_at + 3.minutes
          )
        end
        status = if challenger_score && opponent_score
          "resolved"
        elsif challenger_score || opponent_score
          "one_scored"
        else
          "active"
        end

        invitation = demo_invitation("origin-#{key}")
        invitation.assign_attributes(
          challenger_person: challenger,
          recipient_person: opponent,
          challenger_run: challenger_run,
          challenger_score: challenger_score,
          claimed_by_person: opponent,
          rematch_of_duel: rematch_of,
          token_digest: invitation.token_digest.presence || DuelInvitation.digest("#{SOURCE}:#{@target.id}:origin:#{key}"),
          status: "claimed",
          source: SOURCE,
          channel: "noche",
          share_handoff_at: accepted_at - 4.minutes,
          delivered_at: accepted_at - 3.minutes,
          seen_at: accepted_at - 2.minutes,
          claimed_at: accepted_at,
          expires_at: @now + EXPIRES_IN,
          metadata: { "seed_key" => scoped_key("origin-#{key}"), "target_person_id" => @target.id }
        )
        invitation.save!

        duel = invitation.street_duel || StreetDuel.find_by(origin_invitation: invitation) || StreetDuel.new(origin_invitation: invitation)
        target_is_challenger = challenger.id == @target.id
        target_seen_at = status == "resolved" && seen_for_target ? accepted_at + 15.minutes : nil
        duel.assign_attributes(
          challenger_person: challenger,
          opponent_person: opponent,
          challenger_run: challenger_run,
          opponent_run: opponent_run,
          challenger_score: challenger_score,
          opponent_score: opponent_score,
          status: status,
          accepted_at: accepted_at,
          resolved_at: status == "resolved" ? accepted_at + 10.minutes : nil,
          challenger_result_seen_at: target_is_challenger ? target_seen_at : (status == "resolved" ? accepted_at + 12.minutes : nil),
          opponent_result_seen_at: target_is_challenger ? (status == "resolved" ? accepted_at + 12.minutes : nil) : target_seen_at,
          rematch_of: rematch_of,
          expires_at: @now + EXPIRES_IN
        )
        duel.save!
        invitation.update!(street_duel: duel)
        duel.update_columns(created_at: accepted_at, updated_at: accepted_at)
        invitation.update_columns(created_at: accepted_at - 4.minutes, updated_at: accepted_at)
        duel
      end

      def demo_invitation(key)
        DuelInvitation
          .where(source: SOURCE)
          .where("metadata ->> 'seed_key' = ?", scoped_key(key))
          .first_or_initialize
      end

      def finished_run(person, key, score:, pack_id:, opened_at:)
        pack = QuizDefinition.catalog.find_pack(pack_id)
        run = QuizRun.find_or_initialize_by(
          device_digest: GameSession.digest_token("#{SOURCE}:#{@target.id}:#{key}")
        )
        run.assign_attributes(
          person: person,
          pack_id: pack.id,
          position: pack.questions.size,
          score: score,
          status: "finished",
          opened_at: opened_at,
          ends_at: nil
        )
        run.save!
        run
      end

      def pack_for(key)
        QuizDefinition.catalog.pack_ids[key.each_byte.sum % QuizDefinition.catalog.pack_ids.size]
      end

      def scoped_key(key)
        "#{@target.id}:#{key}"
      end
  end
end

target = if ENV["PERSON_ID"].present?
  Person.find(ENV.fetch("PERSON_ID"))
elsif ENV["NAME"].present?
  Person.named(ENV.fetch("NAME")).joins(:person_devices).order(id: :desc).first!
else
  raise ArgumentError, "provide PERSON_ID=<id> or NAME=<profile name>"
end

result = Seeds::DuelCampusDemo.new(target: target).call
puts <<~MESSAGE
  Campus demo ready for #{result.fetch(:target).display_name} (##{result.fetch(:target).id})
  incoming=#{result.fetch(:incoming)} active=#{result.fetch(:active)} unseen_results=#{result.fetch(:unseen_results)} outgoing=#{result.fetch(:outgoing)}
  Open: http://127.0.0.1:#{ENV.fetch("PORT", 3091)}/desafios
MESSAGE
