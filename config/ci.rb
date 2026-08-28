# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: Service worker", "node --test test/javascript/service_worker_push_test.mjs"
  step "Tests: Rails", "env CI=1 COVERAGE=1 bin/rails test"
  step "Coverage: SimpleCov ≥ 90%", "ruby -e 'abort \"Run tests first\" unless File.exist?(\"coverage/.last_run.json\"); require \"json\"; pct = JSON.parse(File.read(\"coverage/.last_run.json\")).dig(\"result\", \"line\"); abort \"coverage \#{pct}% < 90%\" if pct.to_f < 90; puts \"coverage \#{pct}%\"'"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # System tests live in `bin/rails test` and skip when Chrome is missing.

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
