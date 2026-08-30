# frozen_string_literal: true

require "digest"

module Seeds
  class ScriptureCircleDemo
    REFERENCE = "ot/ps/52"
    LOCALE = "fr"

    def initialize(target:, now: Time.current.change(usec: 0), environment: Rails.env)
      @target = target
      @ward = target.ward || raise(ArgumentError, "the selected profile must already belong to a ward")
      @now = now
      @environment = environment.to_s
      @created = Hash.new(0)
      @reused = Hash.new(0)
    end

    def call
      raise "The Scripture Reader demo seed is development-only" unless @environment.in?(%w[development test])

      ApplicationRecord.transaction do
        @ward.update!(scripture_circle_mode: "active")
        @people = seed_people
        @thread = @ward.scripture_circle_threads.find_or_initialize_by(reference: REFERENCE)
        count_record(@thread, :threads)
        @thread.save!
        seed_guide
        seed_reader_history
        seed_posts
      end

      {
        target: @target,
        ward: @ward,
        thread: @thread,
        posts: @thread.scripture_circle_posts.count,
        open_votes: @thread.scripture_circle_posts.joins(:scripture_circle_moderation_proposals)
          .merge(ScriptureCircleModerationProposal.open).distinct.count,
        created: @created,
        reused: @reused
      }
    end

    private

      def seed_people
        {
          david: [ "David", "delfin" ],
          sophie: [ "Sophie", "aguila" ],
          ingrid: [ "Ingrid", "tortuga" ],
          carmen: [ "Carmen", "colibri" ],
          noe: [ "Noé", "oveja" ]
        }.transform_values do |given_name, avatar_key|
          person = @ward.people.find_or_initialize_by(
            given_name_key: Person.name_key(given_name),
            family_name_key: Person.name_key("Démo")
          )
          count_record(person, :people)
          person.assign_attributes(
            given_name:, family_name: "Démo", avatar_key:,
            favorite_year: 2000, locale: @target.locale
          )
          person.save!
          person
        end
      end

      def seed_guide
        copy = {
          "es" => [ "David ante las palabras que hieren", "El salmo contrapone la lengua que destruye con la confianza que echa raíces en la bondad de Dios.", "El título sitúa esta oración después de la denuncia de Doeg el edomita ante Saúl, cuando David vivía amenazado." ],
          "pt-BR" => [ "Davi diante das palavras que ferem", "O salmo contrapõe a língua que destrói à confiança que cria raízes na bondade de Deus.", "O título situa esta oração após Doegue, o edomita, denunciar Davi a Saul, quando Davi vivia sob ameaça." ],
          "fr" => [ "David face aux paroles qui blessent", "Le psaume oppose la langue qui détruit à la confiance qui prend racine dans la bonté de Dieu.", "Le titre situe cette prière après la dénonciation de David auprès de Saül par Doëg l’Édomite, alors que David vivait sous la menace." ],
          "en" => [ "David facing words that wound", "The psalm contrasts a destructive tongue with trust rooted in the goodness of God.", "The title places this prayer after Doeg the Edomite reported David to Saul, while David was living under threat." ]
        }
        copy.each do |locale, (title, summary, historical_context)|
          guide = ScriptureChapterGuide.published.find_by(reference: REFERENCE, locale:) ||
            ScriptureChapterGuide.find_or_initialize_by(reference: REFERENCE, locale:, revision: 1)
          count_record(guide, :guides)
          guide.assign_attributes(
            welcome_title: title,
            summary:,
            historical_context:,
            literary_structure: "Accusation (vv. 1–5), divine judgment (vv. 6–7), trust and praise (vv. 8–9).",
            key_terms: [ { "term" => "olivier", "verse" => 8 } ],
            theme_key: "truth_and_trust",
            source_citations: [ { "label" => "Psaume 52", "url" => Quizzes::Scripture.page_url(REFERENCE) } ],
            status: "published",
            reviewed_by: "Noche Live — démo éditoriale",
            published_at: @now
          )
          guide.save!
        end
      end

      def seed_reader_history
        unless @target.scripture_reader_preference
          @target.create_scripture_reader_preference!(
            font_scale: 115,
            line_height_key: "comfortable",
            measure_key: "comfortable",
            font_family_key: "editorial",
            background_key: "paper",
            illustrations_enabled: true
          )
          @created[:preferences] += 1
        else
          @reused[:preferences] += 1
        end
        progress = @target.scripture_reading_progresses.find_by(reference: REFERENCE, locale: LOCALE)
        if progress
          @reused[:progresses] += 1
        else
          Scriptures::ReadingProgress::Record.call(
            person: @target, reference: REFERENCE, locale: LOCALE,
            last_verse: 3, progress_ratio: 0.32, at: @now - 1.day
          )
          @created[:progresses] += 1
        end
        seed_mark(start_verse: 3, end_verse: 3, text: "Tu aimes le mal plutôt que le bien, tu aimes le mensonge plutôt que la vérité.", visual_style: "highlight", color_key: "gold")
        seed_mark(start_verse: 5, end_verse: 5, text: "Tu aimes toutes les paroles qui dévorent, toi, langue trompeuse.", visual_style: "underline", color_key: "clay", note_body: "Relire ce contraste avec le verset 8.")
        seed_mark(start_verse: 8, end_verse: 8, text: "Mais moi, je suis comme un olivier florissant dans la maison de Dieu.", visual_style: "none", bookmarked_at: @now - 2.hours, intent_key: "promise")

        [ @target, *@people.values ].each_with_index do |person, index|
          Scriptures::RecordRead.call(
            reference: REFERENCE,
            reader_digest: GameSession.digest_token("scripture-circle-demo:#{person.id}"),
            locale: LOCALE,
            person:,
            at: @now - index.minutes
          )
        end
      end

      def seed_mark(start_verse:, end_verse:, text:, **attributes)
        marker = Digest::SHA256.hexdigest("scripture-reader-demo-v1:#{text}")
        mark = @target.scripture_marks.find_by(source_digest: marker)
        mark ||= @target.scripture_marks.find_by(
          reference: REFERENCE, locale: LOCALE, anchor_scope: "passage",
          start_verse:, start_offset: 0, end_verse:, end_offset: text.length,
          selected_text: text
        )
        mark ||= @target.scripture_marks.build(
          reference: REFERENCE, locale: LOCALE, anchor_scope: "passage",
          start_verse:, start_offset: 0, end_verse:, end_offset: text.length
        )
        count_record(mark, :marks)
        mark.assign_attributes({ selected_text: text, source_digest: marker }.merge(attributes))
        mark.save!
      end

      def seed_posts
        welcome = seed_post(
          seed_key: "target-welcome", person: @target, kind: "reflection", verse: 8, age: 9.hours,
          body: "L’image de l’olivier m’apaise : la fidélité ne fait pas de bruit, mais elle demeure enracinée quand tout devient confus."
        )
        welcome.update!(
          body: "L’image de l’olivier m’apaise : la fidélité ne fait pas de bruit, mais elle demeure enracinée même quand tout devient confus.",
          edited_at: @now - 8.hours
        ) unless welcome.body.include?("même quand")

        question = seed_post(
          seed_key: "sophie-question", person: @people.fetch(:sophie), kind: "question", verse: 3, age: 7.hours,
          body: "Comment choisir la vérité quand une parole blessante semble pourtant nous donner raison sur le moment ?"
        )
        reply = seed_post(
          seed_key: "david-reply", person: @people.fetch(:david), kind: "reply", verse: 3, age: 6.hours, parent: question,
          body: "Je crois que le verset nous invite d’abord à regarder ce que nos mots font grandir, pas seulement s’ils sont exacts."
        )
        seed_post(
          seed_key: "ingrid-reply-to-reply", person: @people.fetch(:ingrid), kind: "reply", verse: 3, age: 5.hours, parent: reply,
          body: "Oui — prendre quelques secondes avant de répondre change souvent la direction de toute la conversation."
        )

        deleted = seed_post(
          seed_key: "carmen-deleted", person: @people.fetch(:carmen), kind: "reflection", verse: 5, age: 4.hours,
          body: "Cette réflexion a été retirée par son auteur."
        )
        seed_post(
          seed_key: "ingrid-reply-deleted", person: @people.fetch(:ingrid), kind: "reply", verse: 5, age: 3.hours, parent: deleted,
          body: "Je garde malgré tout la question que cela avait ouverte pour moi."
        )
        ScriptureCircles::Posts::Destroy.call(person: @people.fetch(:carmen), post_id: deleted.id) unless deleted.status == "author_deleted"

        voting = seed_post(
          seed_key: "noe-open-vote", person: @people.fetch(:noe), kind: "reflection", verse: 4, age: 2.hours,
          body: "Je me demande comment accueillir une parole difficile sans répondre avec la même dureté."
        )
        seed_open_vote(voting)

        resolved = seed_post(
          seed_key: "carmen-resolved-vote", person: @people.fetch(:carmen), kind: "reflection", verse: 2, age: 5.days,
          body: "Corps historique conservé en base mais jamais réexposé après la décision de censure."
        )
        seed_resolved_vote(resolved)
      end

      def seed_post(seed_key:, person:, kind:, verse:, body:, age:, parent: nil)
        marker = "scripture-reader-demo-v1:#{seed_key}"
        post = @thread.scripture_circle_posts.find_by(selected_text: marker)
        post ||= @thread.scripture_circle_posts.find_by(
          person:, kind:, start_verse: verse, end_verse: verse, parent:, selected_text: "Psaume 52:#{verse}"
        )
        post ||= @thread.scripture_circle_posts.build
        count_record(post, :posts)
        was_new = post.new_record?
        post.assign_attributes(
          ward: @ward, person:, kind:, parent:, start_verse: verse, end_verse: verse,
          locale: LOCALE,
          body:,
          selected_text: marker
        )
        post.save!
        post.update_columns(created_at: @now - age, updated_at: @now - age) if was_new
        post
      end

      def seed_open_vote(post)
        proposal = post.scripture_circle_moderation_proposals.open.first
        proposal ||= ScriptureCircles::Moderations::Propose.call(
          person: @people.fetch(:sophie),
          post_id: post.id,
          reason_key: "uncharitable",
          reason_details: "Le ton paraît incompatible avec une conversation fraternelle.",
          at: @now - 6.hours
        )
        cast_once(proposal, @target, "yes", at: @now - 5.hours)
        cast_once(proposal, @people.fetch(:david), "yes", at: @now - 4.hours)
        cast_once(proposal, @people.fetch(:sophie), "yes", at: @now - 3.hours)
        cast_once(proposal, @people.fetch(:ingrid), "no", at: @now - 2.hours)
        cast_once(proposal, @people.fetch(:carmen), "no", at: @now - 1.hour)
      end

      def seed_resolved_vote(post)
        proposal = post.scripture_circle_moderation_proposals.order(:id).last
        return proposal if proposal&.status.in?(%w[censored kept])

        proposal ||= ScriptureCircles::Moderations::Propose.call(
          person: @target,
          post_id: post.id,
          reason_key: "personal_attack",
          at: @now - 3.days
        )
        cast_once(proposal, @target, "yes", at: @now - 60.hours)
        cast_once(proposal, @people.fetch(:david), "yes", at: @now - 59.hours)
        cast_once(proposal, @people.fetch(:sophie), "yes", at: @now - 58.hours)
        cast_once(proposal, @people.fetch(:ingrid), "no", at: @now - 57.hours)
        ScriptureCircles::Moderations::ResolveDue.resolve_one(proposal, at: @now)
      end

      def cast_once(proposal, person, choice, at:)
        ballot = proposal.scripture_circle_moderation_ballots.find_by(voter_person: person)
        return ballot if ballot&.choice == choice

        ScriptureCircles::Moderations::CastBallot.call(person:, proposal_id: proposal.id, choice:, at:)
      end

      def count_record(record, key)
        (record.new_record? ? @created : @reused)[key] += 1
      end
  end
end

unless ENV["SCRIPTURE_CIRCLE_DEMO_DEFINITION_ONLY"] == "1"
  raise "The Scripture Reader demo seed is development-only" unless Rails.env.development?

  target = if ENV["PERSON_ID"].present?
    Person.find(ENV.fetch("PERSON_ID"))
  elsif ENV["NAME"].present?
    Person.named(ENV.fetch("NAME")).joins(:person_devices).where.not(ward_id: nil)
      .order("person_devices.last_seen_at DESC NULLS LAST").first!
  else
    Person.named("Tracy").joins(:person_devices).where.not(ward_id: nil)
      .order("person_devices.last_seen_at DESC NULLS LAST").first ||
      raise(ArgumentError, "provide PERSON_ID=<id> or NAME=<profile name>")
  end

  result = Seeds::ScriptureCircleDemo.new(target:).call
  port = ENV.fetch("PORT", 3091)
  base = "http://127.0.0.1:#{port}/escrituras/#{Seeds::ScriptureCircleDemo::REFERENCE}"
  puts <<~MESSAGE
    Scripture Reader demo ready for #{result.fetch(:target).display_name} (##{result.fetch(:target).id})
    ward=#{result.fetch(:ward).name} posts=#{result.fetch(:posts)} open_votes=#{result.fetch(:open_votes)}
    created=#{result.fetch(:created).sort.to_h.inspect}
    reused=#{result.fetch(:reused).sort.to_h.inspect}
    Reader:  #{base}
    Circle:  #{base}?circle=1
    Profile: http://127.0.0.1:#{port}/jugadores/#{result.fetch(:target).id}/perfil/publicaciones-del-circulo
  MESSAGE
end
