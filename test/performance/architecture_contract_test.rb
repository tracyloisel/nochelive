require "test_helper"
require "erb"
require "yaml"

class ArchitectureContractTest < ActiveSupport::TestCase
  test "production realtime uses Redis instead of database polling" do
    source = Rails.root.join("config/cable.yml").read
    cable = YAML.safe_load(ERB.new(source).result)
    production = cable.fetch("production")

    assert_equal "redis", production.fetch("adapter")
    assert_includes source, 'ENV["REDIS_URL"]'
    refute production.key?("polling_interval")
  end

  test "browser presence heartbeats stay on the websocket" do
    source = Rails.root.join("app/javascript/controllers/presence_controller.js").read

    assert_includes source, "cable.subscribeTo"
    assert_includes source, 'perform("heartbeat")'
    refute_match(/\bfetch\s*\(/, source)
    refute_match(/XMLHttpRequest/, source)
  end

  test "render provisions one shared realtime store for web and worker" do
    blueprint = YAML.safe_load(Rails.root.join("render.yaml").read)
    services = blueprint.fetch("services")
    realtime = services.find { |service| service["type"] == "keyvalue" }

    assert_equal "nochelive-realtime", realtime.fetch("name")
    assert_equal "allkeys-lru", realtime.fetch("maxmemoryPolicy")

    %w[web worker].each do |type|
      service = services.find { |candidate| candidate["type"] == type }
      variables = service.fetch("envVars").index_by { |variable| variable.fetch("key") }
      redis = variables.fetch("REDIS_URL").fetch("fromService")

      assert_equal "nochelive-realtime", redis.fetch("name")
      assert_equal "keyvalue", redis.fetch("type")
    end
  end

  test "production keeps cache and immutable asset delivery off PostgreSQL and Puma" do
    production = Rails.root.join("config/environments/production.rb").read
    blueprint = Rails.root.join("render.yaml").read

    assert_includes production, "config.cache_store = :redis_cache_store"
    assert_includes blueprint, "https://nochelive-assets-prod.storage.googleapis.com"
    refute_includes blueprint, "RAILS_SERVE_STATIC_FILES"
  end

  test "asset host middleware never buffers the complete response" do
    source = Rails.root.join("lib/public_asset_host.rb").read

    assert_includes source, "RewritingBody.new(body, host)"
    refute_match(/body\.each\s*\{[^}]*source\s*<</m, source)
    refute_match(/rewritten\.bytesize/, source)
  end
end
