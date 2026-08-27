# Idempotent playable demo for development (and CI seed:replant).
PRESENTER_TOKEN = "noche-demo"
WARD_TOKEN = "rama-demo"
DEMO_CODE = "DEMO"

ward = Ward.find_or_initialize_by(code: "RAMA")
ward.assign_attributes(
  name: "Rama Benidorm",
  emblem: "paloma",
  chapel_name: "Capilla de Benidorm",
  chapel_address: "Avinguda Alfonso Puchades, 27",
  city: "Benidorm",
  region: "Alicante",
  postal_code: "03502",
  country_code: "ES",
  listed: true,
  stake_name: "Elche Spain Stake",
  stake_unit_id: "527556",
  presenter_token_digest: GameSession.digest_token(WARD_TOKEN),
  locator_payload: (ward.locator_payload || {}).merge(
    "hours" => {
      "code" => "Su 10:00-12:00",
      "primary" => { "hour" => { "code" => "10:00:00" } },
      "days" => [ { "day" => { "code" => "SUNDAY" }, "hours" => { "ranges" => [ { "start" => { "code" => "10:00:00" }, "finish" => { "code" => "12:00:00" } } ] } } ]
    }
  )
)
ward.save!

alicante = Ward.find_or_initialize_by(code: "ALICANTE")
alicante.assign_attributes(
  name: "Rama Alicante",
  emblem: "estrella",
  chapel_name: "Capilla de Alicante",
  city: "Alicante",
  region: "Alicante",
  country_code: "ES",
  listed: true,
  stake_name: "Elche Spain Stake",
  stake_unit_id: "527556",
  presenter_token_digest: GameSession.digest_token("alicante-demo"),
  locator_payload: (alicante.locator_payload || {}).except("sunday_schedule").merge(
    "hours" => {
      "code" => "Su 10:00-12:00",
      "primary" => { "hour" => { "code" => "10:00:00" } },
      "days" => [ { "day" => { "code" => "SUNDAY" }, "hours" => { "ranges" => [ { "start" => { "code" => "10:00:00" }, "finish" => { "code" => "12:00:00" } } ] } } ]
    }
  )
)
alicante.save!

valencia = Ward.find_or_initialize_by(code: "VALX")
valencia.assign_attributes(
  name: "Rama Valencia",
  emblem: "ola",
  chapel_name: "Capilla de Valencia",
  city: "Valencia",
  region: "Valencia",
  country_code: "ES",
  listed: true,
  presenter_token_digest: GameSession.digest_token("valx-demo")
)
valencia.save!

leones_season = ward.ward_teams.find_or_create_by!(name: "Leones de Judá") { |row| row.emblem = "leon" }
casa_season = ward.ward_teams.find_or_create_by!(name: "Casa de David") { |row| row.emblem = "ola" }

carmen_g = ward.people.find_or_initialize_by(given_name_key: "carmen", family_name_key: "garcia", avatar_key: "delfin")
carmen_g.assign_attributes(given_name: "Carmen", family_name: "García", favorite_year: 1833, last_ward_team: leones_season)
carmen_g.save!

carmen_l = ward.people.find_or_initialize_by(given_name_key: "carmen", family_name_key: "lopez", avatar_key: "aguila", favorite_year: 2012)
carmen_l.assign_attributes(given_name: "Carmen", family_name: "López", last_ward_team: casa_season)
carmen_l.save!

pili = ward.people.find_or_initialize_by(given_name_key: "pili", family_name_key: "", avatar_key: "tortuga", favorite_year: 1830)
pili.assign_attributes(given_name: "Pili", family_name: nil, last_ward_team: leones_season)
pili.save!

def seed_person(ward, given, family, avatar, year)
  person = ward.people.find_or_initialize_by(given_name_key: Person.name_key(given), family_name_key: Person.name_key(family))
  person.assign_attributes(given_name: given, family_name: family, avatar_key: avatar, favorite_year: year)
  person.save!
  person
end

def seed_quiz_total(person, score, pack_id: "coronas")
  digest = GameSession.digest_token("seed-liga-#{person.id}-#{pack_id}")
  run = QuizRun.find_or_initialize_by(device_digest: digest)
  run.assign_attributes(person:, pack_id:, position: 10, score:, status: "finished", opened_at: 4.days.ago)
  run.save!
  run
end

miguel = seed_person(ward, "Miguel", nil, "perro", 2008)
sophie = seed_person(ward, "Sophie", nil, "oveja", 2011)
jean_marc = seed_person(ward, "Jean Marc", nil, "aguila", 2003)
lucas_alicante = seed_person(alicante, "Lucas", nil, "gato", 2007)
ines_alicante = seed_person(alicante, "Inés", nil, "colibri", 2009)
sofia_alicante = seed_person(alicante, "Sofía", nil, "delfin", 2004)
diego_alicante = seed_person(alicante, "Diego", nil, "aguila", 2001)
marina_alicante = seed_person(alicante, "Marina", nil, "oveja", 2006)

seed_quiz_total(pili, 58)
seed_quiz_total(carmen_g, 72)
seed_quiz_total(miguel, 41)
seed_quiz_total(sophie, 18)
seed_quiz_total(jean_marc, 65)
seed_quiz_total(lucas_alicante, 61)
seed_quiz_total(ines_alicante, 54)
seed_quiz_total(sofia_alicante, 206)
seed_quiz_total(diego_alicante, 156)
seed_quiz_total(marina_alicante, 98)

# Fill the demo world across several packs so the stake rivalry reads as a
# mature community, while every number still comes from real QuizRun rows.
%w[placas hermanas abish profetas jehova nazareno moises abraham].zip([ 99, 99, 99, 99, 99, 99, 99, 95 ]).each do |pack_id, score|
  seed_quiz_total(miguel, score, pack_id:)
end
%w[placas hermanas abish profetas jehova nazareno moises abraham kolob premortal exaltacion].zip([ 97, 97, 97, 97, 97, 96, 96, 96, 96, 96, 96 ]).each do |pack_id, score|
  seed_quiz_total(lucas_alicante, score, pack_id:)
end

def seed_duel(token:, challenger:, opponent:, challenger_score:, opponent_score:, challenger_position:, opponent_position:, status:, updated_at: Time.current)
  duel = StreetDuel.find_or_initialize_by(token:)
  duel.assign_attributes(
    ward: challenger.ward,
    challenger_person: challenger,
    opponent_person: opponent,
    challenger_ward: challenger.ward,
    opponent_ward: opponent.ward,
    stake_unit_id: challenger.ward.stake_unit_id,
    pack_id: "coronas",
    status:,
    expires_at: 30.days.from_now,
    challenger_score: status == "resolved" ? challenger_score : nil,
    opponent_score: status == "resolved" ? opponent_score : nil,
    challenger_delta: status == "resolved" ? (challenger_score >= opponent_score ? 12 : -3) : nil,
    opponent_delta: status == "resolved" ? (opponent_score >= challenger_score ? 12 : -3) : nil
  )
  duel.save!

  [ [ challenger, challenger_score, challenger_position, "challenger" ], [ opponent, opponent_score, opponent_position, "opponent" ] ].each do |person, score, position, role|
    run = QuizRun.find_or_initialize_by(device_digest: GameSession.digest_token("seed-duel-#{token}-#{role}"))
    run.assign_attributes(person:, pack_id: "coronas", position:, score:, status: position >= 10 ? "finished" : "open", opened_at: updated_at - 5.minutes, street_duel: duel)
    run.save!
    duel.public_send("#{role}_run=", run)
  end
  duel.save!
  duel.update_columns(updated_at:)
  duel
end

seed_duel(token: "seed-live-carmen", challenger: carmen_g, opponent: pili, challenger_score: 28, opponent_score: 34, challenger_position: 10, opponent_position: 6, status: "challenger_done")
seed_duel(token: "seed-live-jean", challenger: pili, opponent: jean_marc, challenger_score: 21, opponent_score: 27, challenger_position: 3, opponent_position: 10, status: "challenger_done")

7.times do |index|
  pili_wins = index.even?
  seed_duel(
    token: "seed-h2h-carmen-#{index}", challenger: pili, opponent: carmen_g,
    challenger_score: pili_wins ? 48 : 34, opponent_score: pili_wins ? 39 : 47,
    challenger_position: 10, opponent_position: 10, status: "resolved", updated_at: (index + 1).days.ago
  )
end

8.times do |index|
  seed_duel(
    token: "seed-stake-alicante-#{index}", challenger: miguel, opponent: (index.even? ? lucas_alicante : ines_alicante),
    challenger_score: index < 5 ? 52 : 37, opponent_score: index < 5 ? 44 : 49,
    challenger_position: 10, opponent_position: 10, status: "resolved", updated_at: (index + 1).hours.ago
  )
end

# Keep the RAMA hub socially alive with real profiles and real adventure totals.
[
  [ carmen_g, "seed-online-carmen-g", 10 ],
  [ carmen_l, "seed-online-carmen-l", 6 ]
].each do |person, device_token, correct_answers|
  PersonDevice.find_or_create_by!(person:, device_token:)
  Presences::StreetHeartbeat.call(person:, device_token:)

  next if QuizRun.adventure.finished.exists?(person:, pack_id: "coronas")

  run = Quizzes::StartPack.call(
    device_digest: GameSession.digest_token(device_token),
    person_id: person.id,
    pack_id: "coronas"
  ).run
  while run.open?
    choice = run.position <= correct_answers ? run.question.correct_choice : ""
    Quizzes::Submit.call(run:, choice_key: choice)
    Quizzes::Advance.call(run: run.reload)
    run.reload
  end
end

digest = GameSession.digest_token(PRESENTER_TOKEN)
night = GameSession.where(code: DEMO_CODE).where.not(status: "finished").first

if night.nil?
  night = Nights::Start.call(ward:)
  night.update_columns(
    code: DEMO_CODE,
    presenter_token_digest: digest,
    status: "lobby"
  )
else
  night.update!(presenter_token_digest: digest, ward: ward)
end

leones = night.teams.find_or_create_by!(name: "Leones de Judá") { |team| team.emblem = "leon" }
leones.update!(ward_team: leones_season)
casa = night.teams.find_or_create_by!(name: "Casa de David") { |team| team.emblem = "ola" }
casa.update!(ward_team: casa_season)

lucia = night.players.find_or_initialize_by(client_token: "seed-lucia")
lucia.update!(name: "Lucía", role: "participant", location: "room", last_seen_at: Time.current, avatar_key: "loro")
TeamMembership.find_or_create_by!(player: lucia, team: leones)

daniel = night.players.find_or_initialize_by(client_token: "seed-daniel")
daniel.update!(name: "Daniel", role: "participant", location: "remote", last_seen_at: Time.current, avatar_key: "elefante")
Teams::Seat.call(night: night, player: daniel)

night.missionaries.find_or_create_by!(name: "Élder Soto")
night.missionaries.find_or_create_by!(name: "Hermana Clark")

quiz_digest = GameSession.digest_token("noche-quiz-demo")
unless QuizRun.exists?(device_digest: quiz_digest)
  pack = QuizDefinition.catalog.find_pack("coronas")
  demo_run = QuizRun.create!(
    device_digest: quiz_digest,
    pack_id: pack.id,
    position: pack.questions.size,
    score: pack.questions.sum(&:points),
    status: "finished",
    opened_at: Time.current
  )
  pack.questions.each do |question|
    QuizAnswer.find_or_create_by!(device_digest: quiz_digest, pack_id: pack.id, question_id: question.id) do |row|
      row.quiz_run = demo_run
      row.choice_key = question.correct_choice
      row.correct = true
    end
  end
end

host = ENV.fetch("APP_HOST", "http://localhost:3000")

puts <<~MSG

  Rama Benidorm lista. Código rama: RAMA
  Rama Valencia lista. Código rama: VALX
  Capilla: Avinguda Alfonso Puchades, 27, 03502 Benidorm
  Secreto rama: #{WARD_TOKEN}
  Noche: #{DEMO_CODE}
  Jugadores: #{host}
  Presentador: #{host}/p/#{DEMO_CODE}?token=#{PRESENTER_TOKEN}

MSG
