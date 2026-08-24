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
      TeamMembership.create!(player: player, team: team) if team
      player
    end

    def add_team(night, name:, emblem: "leon")
      night.teams.create!(name: name, emblem: emblem)
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
    return unless team

    post night_team_memberships_path(night.code, team)
    follow_redirect! while response.redirect?
  end

  def sign_in_presenter(night, token: nil)
    token ||= presenter_token_for(night)
    night.update!(presenter_token_digest: GameSession.digest_token(token)) unless night.presenter_token_matches?(token)
    get presenter_gate_path(night.code, token: token)
    follow_redirect! if response.redirect?
  end

  def presenter_token_for(night)
    return "presenter-secret" if night.code == "DAVID"
    return "lobby-secret" if night.code == "ELIAS"
    return "ended-secret" if night.code == "QUIT"

    night.presenter_token || "test-token"
  end
end
