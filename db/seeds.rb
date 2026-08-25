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
  presenter_token_digest: GameSession.digest_token(WARD_TOKEN)
)
ward.save!

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

host = ENV.fetch("APP_HOST", "http://localhost:3000")

puts <<~MSG

  Rama Benidorm lista. Código rama: RAMA
  Capilla: Avinguda Alfonso Puchades, 27, 03502 Benidorm
  Secreto rama: #{WARD_TOKEN}
  Noche: #{DEMO_CODE}
  Jugadores: #{host}
  Presentador: #{host}/p/#{DEMO_CODE}?token=#{PRESENTER_TOKEN}

MSG
