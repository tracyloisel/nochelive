require "fileutils"
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/db/"
  add_filter "app/mailers"
  add_filter "app/jobs"
  add_filter "app/channels"
  track_files "app/**/*.rb"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Minitest.after_run do
  result = SimpleCov.result
  test_count = Minitest::Runnable.runnables.sum { |klass| klass.runnable_methods.size }
  enforce = ENV["CI"].present? || ENV["COVERAGE"] == "1" || test_count >= 80
  next unless enforce

  percent = result.covered_percent
  if percent < 90
    warn "Line coverage (#{percent.round(2)}%) is below the required 90%."
    exit! 2
  end
end

module ActiveSupport
  class TestCase
    parallelize(workers: 1)
    fixtures :all

    def create_night
      Nights::Start.call(ward: wards(:blank))
    end

    def add_player(night, name:, team: nil, location: "room")
      player = night.players.create!(
        name: name,
        role: "participant",
        location: location,
        client_token: SecureRandom.uuid,
        avatar_key: "delfin"
      )
      if location == "remote"
        Teams::Seat.call(night:, player:)
      elsif team
        TeamMembership.create!(player: player, team: team)
      end
      player
    end

    def add_team(night, name:, emblem: "leon")
      night.teams.create!(name: name, emblem: emblem)
    end

    def extra_ward(i, listed: false, **attrs)
      Ward.create!({
        name: "Rama Extra #{i}",
        code: format("XT%02d", i),
        emblem: "paloma",
        city: "Valencia",
        country_code: "ES",
        country_name: "Spain",
        stake_name: "Valencia Spain Stake",
        listed: listed,
        presenter_token_digest: GameSession.digest_token("xt#{i}")
      }.merge(attrs))
    end

    def mark_person_online(person, connection_id: SecureRandom.uuid)
      Presences::Registry.enter(
        connection_id:,
        person_id: person.id,
        ward_id: person.ward_id,
        role: "test"
      ).entry
    end

    def mark_player_online(player, connection_id: SecureRandom.uuid)
      Presences::Registry.enter(
        connection_id:,
        person_id: player.person_id,
        ward_id: player.game_session.ward_id,
        player_id: player.id,
        night_id: player.game_session_id,
        team_id: player.team&.id,
        role: player.role,
        location: player.location
      ).entry
    end

    setup do
      Presences::Registry.reset!
      Wards::QueryLocator.transport = nil
      Wards::QueryLocator.forced_hits = nil
      Wards::QueryLocator.forced_details = nil
      Wards::QueryLocator.forced_near = nil
    end

    teardown do
      Wards::QueryLocator.transport = nil
      Wards::QueryLocator.forced_hits = nil
      Wards::QueryLocator.forced_details = nil
      Wards::QueryLocator.forced_near = nil
      Notifications::Sender.transport = nil if defined?(Notifications::Sender)
    end

    def with_web_push_enabled(vapid: true, delivery: true)
      previous = %w[WEB_PUSH_ENABLED WEB_PUSH_DELIVERY_ENABLED VAPID_PUBLIC_KEY VAPID_PRIVATE_KEY VAPID_SUBJECT].to_h { |key| [ key, ENV[key] ] }
      ENV["WEB_PUSH_ENABLED"] = "true"
      ENV["WEB_PUSH_DELIVERY_ENABLED"] = delivery.to_s
      if vapid
        ENV["VAPID_PUBLIC_KEY"] = "test-public"
        ENV["VAPID_PRIVATE_KEY"] = "test-private"
        ENV["VAPID_SUBJECT"] = "mailto:test@nochelive.com"
      end
      yield
    ensure
      previous&.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end

    def peel_to_salsa(round)
      round.intro! if round.pending?
      4.times do
        break if round.reload.last_layer?
        Rounds::Peel.call(round:)
      end
      round.reload
    end

    def generated_media_src(source, format: "jpeg", rendition: nil, width: nil)
      asset = Frontend::MediaManifest.fetch_source(source)
      raise "missing responsive media asset for #{source}" unless asset

      renditions = asset.fetch("renditions")
      selected = rendition ? renditions.fetch(rendition.to_s) : renditions.values.first
      variants = selected.fetch("variants").fetch(format.to_s)
      variant = width ? variants.find { |candidate| candidate.fetch("width") == width } : variants.last
      raise "missing #{format} #{width || 'fallback'} variant for #{source}" unless variant

      variant.fetch("src")
    end

    def frontend_css(*surfaces)
      root = Rails.root.join("app/assets/stylesheets")
      paths = [ root.join("application.css") ]
      paths.concat(
        if surfaces.any?
          surfaces.map { |surface| root.join("surfaces/#{surface}.css") }
        else
          Rails.root.glob("app/assets/stylesheets/surfaces/*.css") + [ root.join("duel_campus.css") ]
        end
      )
      paths.map(&:read).join("\n")
    end
  end
end

class ActionDispatch::IntegrationTest
  def join_as(night, name:, location: "room")
    post night_players_path(night.code), params: { name: name, location: location }
    follow_redirect! while response.redirect?
  end

  def sign_in_as_participant(night, name:, location: "room", team: nil)
    post night_players_path(night.code), params: { name: name, location: location }
    follow_redirect! while response.redirect?
    return if location == "remote"
    return unless team

    player = night.players.find_by!(name: name)
    player.team_membership&.destroy!
    TeamMembership.create!(player: player, team: team)
  end

  def seat_of(night, name)
    night.players.find_by!(name: name).reload.team
  end

    def sign_in_ward(ward = wards(:demo), token: "rama-demo")
      post ward_gate_path, params: { code: ward.code, token: token }
      follow_redirect! if response.redirect?
    end

    def sign_in_congregation(ward = wards(:demo))
      post enter_ward_path, params: { code: ward.code }
      follow_redirect! if response.redirect?
    end

    def start_street_play!(pack_id = "coronas")
      post street_pack_start_path(pack_id)
      follow_redirect!
    end

    def sign_in_presenter(night, token: nil)
      token ||= presenter_token_for(night)
      night.update!(presenter_token_digest: GameSession.digest_token(token)) unless night.presenter_token_matches?(token)
      get presenter_gate_path(night.code, token: token)
      follow_redirect! if response.redirect?
    end

    def create_street_profile!(name: "Jugador Test", avatar_key: "delfin")
      post street_profile_path, params: { name:, avatar_key: }
      follow_redirect! if response.redirect?
      Person.order(:id).last
    end

    def start_street_jugar!(pack_id: "coronas")
      sign_in_congregation
      create_street_profile!
      post street_pack_start_path(pack_id)
      follow_redirect!
      QuizRun.open_runs.order(:id).last
    end

  def presenter_token_for(night)
    return "presenter-secret" if night.code == "DAVID"
    return "lobby-secret" if night.code == "ELIAS"
    return "ended-secret" if night.code == "QUIT"

    night.presenter_token || "test-token"
  end
end
