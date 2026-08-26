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

    setup do
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
    end

    def peel_to_salsa(round)
      round.intro! if round.pending?
      4.times do
        break if round.reload.last_layer?
        Rounds::Peel.call(round:)
      end
      round.reload
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

    post night_team_memberships_path(night.code, team)
    follow_redirect! while response.redirect?
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

    def start_street_jugar!(guest: true, pack_id: "coronas")
      sign_in_congregation
      get root_path
      if guest
        post street_profile_path, params: { guest: 1 }
        follow_redirect!
      end
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
