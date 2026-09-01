#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../config/environment"
require "digest"
require "yaml"

PACK_IDS = %w[
  exp_psalms_disappearing_voice
  exp_psalms_nameless_king
  exp_psalms_cry_stone_seek
  exp_psalms_house_table_city
  exp_psalms_suspended_harps
  exp_psalms_everything_breathes
].freeze

PACK_PRESENTATION_SOURCE = [
  {
    "id" => "exp_psalms_disappearing_voice",
    "title" => { "fr" => "La voix qui disparaît", "es" => "La voz que desaparece" },
    "kicker" => { "fr" => "Psaumes 102–103", "es" => "Salmos 102–103" },
    "hook" => {
      "fr" => "Un homme dit que ses jours partent en fumée. Pourtant, son chant est encore là.",
      "es" => "Un hombre dice que sus días se disipan como humo. Sin embargo, su canto sigue ahí."
    },
    "experience" => {
      "fr" => "Passer de la peur de disparaître à une mémoire qui tient.",
      "es" => "Pasar del miedo a desaparecer a una memoria que perdura."
    }
  },
  {
    "id" => "exp_psalms_nameless_king",
    "title" => { "fr" => "Le Roi sans nom", "es" => "El Rey sin nombre" },
    "kicker" => { "fr" => "Psaume 110", "es" => "Salmo 110" },
    "hook" => {
      "fr" => "Dieu réunit un roi et un prêtre dans le même homme. Puis un nom surgit : Melchisédek.",
      "es" => "Dios reúne a un rey y a un sacerdote en la misma persona. Entonces aparece un nombre: Melquisedec."
    },
    "experience" => {
      "fr" => "Entrer dans une cérémonie royale dont la pièce centrale manque.",
      "es" => "Entrar en una ceremonia real a la que le falta la pieza central."
    }
  },
  {
    "id" => "exp_psalms_cry_stone_seek",
    "title" => { "fr" => "Cherche-moi", "es" => "Búscame" },
    "kicker" => { "fr" => "Psaumes 116–119", "es" => "Salmos 116–119" },
    "hook" => {
      "fr" => "Le plus long psaume finit sans triomphe : « Je suis perdu. Cherche-moi. »",
      "es" => "El salmo más largo termina sin triunfo: «Estoy perdido. Búscame»."
    },
    "experience" => {
      "fr" => "Crier, être relevé, puis admettre qu’on a encore besoin d’aide.",
      "es" => "Clamar, ser levantado y admitir que aún necesitas ayuda."
    }
  },
  {
    "id" => "exp_psalms_house_table_city",
    "title" => { "fr" => "La maison que Dieu bâtit", "es" => "La casa que Dios edifica" },
    "kicker" => { "fr" => "Psaumes 127–128", "es" => "Salmos 127–128" },
    "hook" => {
      "fr" => "Tu travailles, tu veilles, tu recommences. Mais est-ce que tout repose vraiment sur toi ?",
      "es" => "Trabajas, velas, vuelves a empezar. Pero ¿de verdad todo descansa sobre ti?"
    },
    "experience" => {
      "fr" => "Travailler vraiment sans prétendre être sa propre fondation.",
      "es" => "Trabajar de verdad sin pretender ser tu propio fundamento."
    }
  },
  {
    "id" => "exp_psalms_suspended_harps",
    "title" => { "fr" => "Les harpes suspendues", "es" => "Las arpas suspendidas" },
    "kicker" => { "fr" => "Psaumes 135–139", "es" => "Salmos 135–139" },
    "hook" => {
      "fr" => "On détruit leur ville. Puis on leur demande de la chanter. Ils suspendent leurs harpes.",
      "es" => "Destruyen su ciudad. Después les piden que la canten. Ellos cuelgan sus arpas."
    },
    "experience" => {
      "fr" => "Écouter ce qui refuse de chanter avant de répondre.",
      "es" => "Escuchar lo que se niega a cantar antes de responder."
    }
  },
  {
    "id" => "exp_psalms_everything_breathes",
    "title" => { "fr" => "Tout ce qui respire", "es" => "Todo lo que respira" },
    "kicker" => { "fr" => "Psaumes 146–150", "es" => "Salmos 146–150" },
    "hook" => {
      "fr" => "Le Dieu qui compte les étoiles s’arrête aussi devant un cœur brisé.",
      "es" => "El Dios que cuenta las estrellas también se detiene ante un corazón quebrantado."
    },
    "experience" => {
      "fr" => "Choisir où placer son espérance, puis rejoindre le chœur.",
      "es" => "Elegir dónde poner tu esperanza y después unirte al coro."
    }
  }
].freeze

# Keep the Council-authored experience notes while sourcing the player-facing
# Home/Map copy from the exact-locale presentation catalogue. This script can
# then never republish Spanish-only door metadata by accident.
PACK_PRESENTATION = PACK_PRESENTATION_SOURCE.map do |row|
  localized = %w[title kicker lede hook].index_with do |field|
    Locale::AVAILABLE.index_with do |locale|
      I18n.t(
        "expedition_pack_presentations.#{row.fetch('id')}.#{field}",
        locale:,
        fallback: false,
        raise: true
      )
    end
  end
  row.merge(localized)
end.freeze

READINGS = [ 102, 103, 110, 116, 117, 118, 119, 127, 128, 135, 136, 137, 138, 139, 146, 147, 148, 149, 150 ].map do |chapter|
  {
    "study" => "ot/ps/#{chapter}",
    "labels" => { "fr" => "Psaume #{chapter}", "es" => "Salmo #{chapter}" }
  }
end.freeze

ward = Ward.find_by!(name: ENV.fetch("WARD_NAME", "Rama Benidorm"))
ward.update!(time_zone: "Europe/Madrid")
player = Person.find(ENV["PLAYER_ID"]) if ENV["PLAYER_ID"].present?
raise "Player #{player.id} is not in #{ward.name}" if player && player.ward_id != ward.id

unit = StudyUnit.find_by!(starts_on: Date.new(2026, 8, 31), ends_on: Date.new(2026, 9, 6))

content = {
  "key" => "ils-ont-crie-vers-dieu-2026",
  "light" => {
    "fr" => "Le Dieu qui me connaît et me relève est digne de toute ma louange.",
    "es" => "El Dios que me conoce y me levanta merece toda mi alabanza."
  },
  "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
  "ceremony_artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
  "readings" => READINGS,
  "questions" => [],
  "expedition" => {
    "id" => "psalms-102-150-2026-08-31",
    "title" => {
      "fr" => "Ça aussi, c’est dans les Psaumes",
      "es" => "Esto también está en los Salmos",
      "en" => "This is in the Psalms too",
      "pt-BR" => "Isso também está nos Salmos"
    },
    "subtitle" => {
      "fr" => "Six portes cachées dans les chants de la semaine",
      "es" => "Seis puertas ocultas en los cantos de la semana",
      "en" => "Six hidden doors in this week’s songs",
      "pt-BR" => "Seis portas escondidas nos cânticos da semana"
    },
    "promise" => {
      "fr" => "Un homme a peur de disparaître. Des exilés refusent de chanter. Un roi devient prêtre. Ouvre une porte et entre dans leur histoire.",
      "es" => "Un hombre teme desaparecer. Unos exiliados se niegan a cantar. Un rey se convierte en sacerdote. Abre una puerta y entra en su historia.",
      "en" => "A man fears he will disappear. Exiles refuse to sing. A king becomes a priest. Open a door and enter their story.",
      "pt-BR" => "Um homem teme desaparecer. Exilados se recusam a cantar. Um rei se torna sacerdote. Abra uma porta e entre na história deles."
    },
    "structure_type" => "constellation",
    "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
    "pack_ids" => PACK_IDS,
    "packs" => PACK_PRESENTATION
  }
}

StudyQuizVersion.transaction do
  unit.update!(
    status: "published",
    copy: unit.copy.deep_merge(
      "fr" => {
        "title" => "31 août – 6 septembre : Ils ont crié vers Dieu",
        "theme" => "Quand il ne reste que la foi",
        "scripture_refs" => READINGS.map { |reading| reading.dig("labels", "fr") }
      },
      "es" => {
        "title" => "31 de agosto–6 de septiembre: Salmos 102–103; 110; 116–119",
        "theme" => "Cuando solo queda la fe",
        "scripture_refs" => READINGS.map { |reading| reading.dig("labels", "es") }
      }
    )
  )
  unit.study_quiz_versions.where(status: "published").where.not(version: 3).update_all(status: "retired")
  version = unit.study_quiz_versions.find_or_initialize_by(version: 3)
  version.update!(
    status: "published",
    editorial_locale: "fr",
    content:,
    content_digest: Digest::SHA256.hexdigest(content.to_json),
    published_at: Time.current
  )
end

zone = Time.find_zone!("Europe/Madrid")
schedules = [
  [ zone.local(2026, 8, 31, 20, 0), PACK_IDS.first(3) ],
  [ zone.local(2026, 9, 4, 20, 0), PACK_IDS.last(3) ]
]

nights = schedules.map do |starts_at, quiz_ids|
  night = GameSession.find_by(ward:, starts_at:)
  if night
    attributes = {}
    attributes[:quiz_pack_ids] = quiz_ids if night.quiz_pack_ids != quiz_ids
    attributes[:duration_hours] = 3 if night.duration_hours != 3
    Nights::Configure.call(night:, attributes:) if attributes.present?
    night.reload
  else
    Nights::Start.call(ward:, quiz_ids:, starts_at:, duration_hours: 3)
  end
end

puts({
  expedition: { study_unit_id: unit.id, quiz_version: 3, starts_on: unit.starts_on, ends_on: unit.ends_on, pack_ids: PACK_IDS },
  player: player && { id: player.id, name: player.display_name, ward: ward.name },
  nights: nights.map do |night|
    {
      id: night.id,
      code: night.code,
      starts_at: night.starts_at.in_time_zone(zone),
      ends_at: night.ends_at.in_time_zone(zone),
      duration_hours: night.duration_hours,
      quiz_pack_ids: night.quiz_pack_ids
    }
  end
}.inspect)
