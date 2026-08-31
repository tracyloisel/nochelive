require "digest"

class LocalizePsalmsExpeditionForBenidorm < ActiveRecord::Migration[8.0]
  PACK_COPY_ES = {
    "exp_psalms_disappearing_voice" => {
      "title" => "La voz que desaparece",
      "kicker" => "Salmos 102–103",
      "hook" => "Un hombre dice que sus días se disipan como humo. Sin embargo, su canto sigue ahí.",
      "experience" => "Pasar del miedo a desaparecer a una memoria que perdura."
    },
    "exp_psalms_nameless_king" => {
      "title" => "El Rey sin nombre",
      "kicker" => "Salmo 110",
      "hook" => "Dios reúne a un rey y a un sacerdote en la misma persona. Entonces aparece un nombre: Melquisedec.",
      "experience" => "Entrar en una ceremonia real a la que le falta la pieza central."
    },
    "exp_psalms_cry_stone_seek" => {
      "title" => "Búscame",
      "kicker" => "Salmos 116–119",
      "hook" => "El salmo más largo termina sin triunfo: «Estoy perdido. Búscame».",
      "experience" => "Clamar, ser levantado y admitir que aún necesitas ayuda."
    },
    "exp_psalms_house_table_city" => {
      "title" => "La casa que Dios edifica",
      "kicker" => "Salmos 127–128",
      "hook" => "Trabajas, velas, vuelves a empezar. Pero ¿de verdad todo descansa sobre ti?",
      "experience" => "Trabajar de verdad sin pretender ser tu propio fundamento."
    },
    "exp_psalms_suspended_harps" => {
      "title" => "Las arpas suspendidas",
      "kicker" => "Salmos 135–139",
      "hook" => "Destruyen su ciudad. Después les piden que la canten. Ellos cuelgan sus arpas.",
      "experience" => "Escuchar lo que se niega a cantar antes de responder."
    },
    "exp_psalms_everything_breathes" => {
      "title" => "Todo lo que respira",
      "kicker" => "Salmos 146–150",
      "hook" => "El Dios que cuenta las estrellas también se detiene ante un corazón quebrantado.",
      "experience" => "Elegir dónde poner tu esperanza y después unirte al coro."
    }
  }.freeze

  READING_LABELS_ES = [ 102, 103, 110, 116, 117, 118, 119, 127, 128, 135, 136, 137, 138, 139, 146, 147, 148, 149, 150 ]
    .to_h { |chapter| [ "ot/ps/#{chapter}", "Salmo #{chapter}" ] }
    .freeze

  def up
    unit = StudyUnit.where(
      starts_on: Date.new(2026, 8, 31),
      ends_on: Date.new(2026, 9, 6)
    ).find do |candidate|
      candidate.study_quiz_versions.exists?(version: 3, status: "published")
    end
    return unless unit

    quiz = unit.study_quiz_versions.find_by(version: 3)
    return unless quiz&.expedition?

    content = quiz.content.deep_dup
    content["light"] = content.fetch("light", {}).merge(
      "es" => "El Dios que me conoce y me levanta merece toda mi alabanza."
    )
    expedition = content.fetch("expedition", {}).deep_dup
    expedition["packs"] = Array(expedition["packs"]).map do |pack|
      id = pack["id"].to_s
      pack.merge(PACK_COPY_ES.fetch(id, {}).transform_values { |value| { "es" => value } })
    end
    content["expedition"] = expedition
    content["readings"] = Array(content["readings"]).map do |reading|
      study = reading["study"].to_s
      label = READING_LABELS_ES[study]
      label ? reading.merge("labels" => reading.fetch("labels", {}).merge("es" => label)) : reading
    end

    copy = unit.copy.deep_dup
    copy["es"] = {
      "title" => "31 de agosto–6 de septiembre: Salmos 102–103; 110; 116–119",
      "theme" => "Cuando solo queda la fe",
      "scripture_refs" => READING_LABELS_ES.values
    }

    StudyQuizVersion.transaction do
      unit.update!(copy:)
      quiz.update!(content:, content_digest: Digest::SHA256.hexdigest(content.to_json))
    end
  end

  def down
    # Keep published player-facing corrections on rollback.
  end
end
