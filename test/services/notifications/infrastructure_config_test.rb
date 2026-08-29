require "test_helper"
require "erb"

class Notifications::InfrastructureConfigTest < ActiveSupport::TestCase
  test "Render has one persistent worker and no duplicate cron service" do
    blueprint = YAML.safe_load_file(Rails.root.join("render.yaml"))
    services = blueprint.fetch("services")
    workers = services.select { |service| service["type"] == "worker" }

    assert_equal 1, workers.size
    assert_equal "bundle exec bin/jobs", workers.first.fetch("startCommand")
    assert_equal 60, workers.first.fetch("maxShutdownDelaySeconds")
    assert_empty services.select { |service| service["type"] == "cron" }
    %w[DATABASE_URL RAILS_MASTER_KEY WEB_PUSH_ENABLED WEB_PUSH_DELIVERY_ENABLED VAPID_PUBLIC_KEY VAPID_PRIVATE_KEY VAPID_SUBJECT].each do |key|
      assert workers.first.fetch("envVars").any? { |row| row["key"] == key }, key
    end

    push_flags = services.filter_map do |service|
      next unless %w[web worker].include?(service["type"])

      service.fetch("envVars").select { |row| %w[WEB_PUSH_ENABLED WEB_PUSH_DELIVERY_ENABLED].include?(row["key"]) }
    end.flatten
    assert_equal 4, push_flags.size
    assert push_flags.all? { |row| row["value"] == "true" }, "push must be live in production on both web and worker services"
  end

  test "Solid Queue gives transactional notifications precedence and owns recurrence" do
    queue_config = YAML.safe_load(ERB.new(Rails.root.join("config/queue.yml").read).result, aliases: true)
    queues = queue_config.dig("production", "workers", 0, "queues")
    recurring = YAML.safe_load_file(Rails.root.join("config/recurring.yml")).fetch("production")

    assert_instance_of Array, queues
    assert_equal "notifications_transactional", queues.first
    assert_includes queues, "notifications_editorial"
    assert_includes queues, "maintenance"
    assert_equal "VerseNotificationCoordinatorJob", recurring.dig("schedule_verse_notifications", "class")
    assert_equal "every 15 minutes", recurring.dig("schedule_verse_notifications", "schedule")
    assert_equal "NightNotificationCoordinatorJob", recurring.dig("schedule_night_notifications", "class")
    assert_equal "every 5 minutes", recurring.dig("schedule_night_notifications", "schedule")
    assert_equal "NotificationsCleanupJob", recurring.dig("clean_notification_records", "class")
    assert_includes Rails.root.join("config/environments/production.rb").read, "queue_adapter = :solid_queue"
  end

  test "the primary database contains every Solid Queue table" do
    %w[
      solid_queue_jobs solid_queue_ready_executions solid_queue_scheduled_executions
      solid_queue_recurring_tasks solid_queue_processes solid_queue_semaphores
    ].each do |table|
      assert ActiveRecord::Base.connection.data_source_exists?(table), table
    end
  end
end
