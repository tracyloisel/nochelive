require "test_helper"

class Wards::BackfillLocatorTest < ActiveSupport::TestCase
  test "fills payload and stake id on ramas that only have a church unit id" do
    dest = extra_ward(31, listed: true, church_unit_id: "999001", city: "Madrid")
    stub_locator_transport

    stats = Wards::BackfillLocator.call

    dest.reload
    assert_equal 1, stats.updated
    assert_equal 0, stats.missing
    assert_equal "520001", dest.stake_unit_id
    assert_equal "Madrid Spain Stake", dest.stake_name
    assert_equal "WARD", dest.locator_payload["type"]
    refute dest.locator_payload.key?("contact")
  end

  test "skips ramas that already have a payload unless forced" do
    dest = extra_ward(32, listed: true, church_unit_id: "999001", city: "Madrid",
      locator_payload: { "type" => "WARD", "stale" => true }, stake_unit_id: "old")
    stub_locator_transport

    stats = Wards::BackfillLocator.call
    assert_equal 0, stats.candidates
    assert_equal "old", dest.reload.stake_unit_id
    assert_equal true, dest.locator_payload["stale"]

    stats = Wards::BackfillLocator.call(force: true)
    dest.reload
    assert_equal 1, stats.updated
    assert_equal "520001", dest.stake_unit_id
    refute dest.locator_payload.key?("stale")
  end

  test "can limit to one church unit id" do
    extra_ward(33, listed: true, church_unit_id: "999001", city: "Madrid")
    extra_ward(34, listed: true, church_unit_id: "333239", city: "Benidorm",
      chapel_address: "Alfonso Puchades 27")
    stub_locator_transport

    stats = Wards::BackfillLocator.call(church_unit_id: "WARD:999001")
    assert_equal 1, stats.candidates
    assert_equal 1, stats.updated
    assert_equal "520001", Ward.find_by!(church_unit_id: "999001").stake_unit_id
    assert_nil Ward.find_by!(church_unit_id: "333239").stake_unit_id
  end

  test "keeps the RAMA product name when Benidorm is backfilled" do
    demo = wards(:demo)
    demo.update!(church_unit_id: "333239")
    stub_locator_transport

    Wards::BackfillLocator.call
    demo.reload

    assert_equal "RAMA", demo.code
    assert_equal "Rama Benidorm", demo.name
    assert_equal "527556", demo.stake_unit_id
    assert_equal "Elche Spain Stake", demo.stake_name
    refute demo.locator_payload.key?("contact")
  end

  test "counts a locator miss without creating or deleting ramas" do
    dest = extra_ward(35, listed: true, church_unit_id: "nope")
    before = Ward.count
    stub_locator_transport

    stats = Wards::BackfillLocator.call
    assert_equal 1, stats.missing
    assert_equal 0, stats.updated
    assert_equal before, Ward.count
    assert_nil dest.reload.locator_payload
  end

  test "does not hit the Church from CI" do
    extra_ward(36, listed: true, church_unit_id: "999001")
    stats = Wards::BackfillLocator.call

    assert_equal 1, stats.missing
    assert_equal 0, stats.updated
    assert_nil Ward.find_by!(church_unit_id: "999001").locator_payload
  end

  test "noche:backfill_locator prints the service stats" do
    extra_ward(37, listed: true, church_unit_id: "999001", city: "Madrid")
    stub_locator_transport
    Rails.application.load_tasks
    Rake::Task["noche:backfill_locator"].reenable

    out, = capture_io { Rake::Task["noche:backfill_locator"].invoke }
    assert_match(/updated=1/, out)
    assert_equal "520001", Ward.find_by!(church_unit_id: "999001").stake_unit_id
  end

  private

    def stub_locator_transport
      madrid = file_fixture("maps_ward_madrid.json").read
      benidorm = file_fixture("maps_ward_benidorm.json").read
      Wards::QueryLocator.transport = lambda do |_url, params|
        ids = params[:ids].to_s
        rows = []
        rows.concat(JSON.parse(madrid)) if ids.include?("999001")
        rows.concat(JSON.parse(benidorm)) if ids.include?("333239")
        rows.to_json
      end
    end
end
