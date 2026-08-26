require "test_helper"

class Wards::SyncDirectoryTest < ActiveSupport::TestCase
  setup do
    @rows = Wards::ParseLocator.call(JSON.parse(file_fixture("meetinghouses.json").read))
  end

  test "creates listed congregaciones and skips non-units already parsed out" do
    stats = Wards::SyncDirectory.call(rows: @rows)

    assert_equal 3, stats[:created]
    assert_equal 1, stats[:updated]
    assert Ward.find_by(church_unit_id: "unit-valencia-1").listed?
    assert_nil Ward.find_by(name: "Madrid Spain Temple")
    assert_equal "branch", Ward.find_by(church_unit_id: "unit-sp-branch").unit_kind
  end

  test "merges Benidorm into RAMA without renaming or new code" do
    stats = Wards::SyncDirectory.call(rows: @rows)
    demo = wards(:demo).reload

    assert_equal 1, stats[:updated]
    assert_equal "RAMA", demo.code
    assert_equal "Rama Benidorm", demo.name
    assert demo.listed?
    assert_equal "unit-benidorm", demo.church_unit_id
    assert_equal "Alicante Spain Stake", demo.stake_name
    assert_equal 1, Ward.where(city: "Benidorm").count
  end

  test "updates RAMA church unit id when the locator id arrives later" do
    demo = wards(:demo)
    demo.update!(church_unit_id: "unit-benidorm")
    Wards::SyncDirectory.call(rows: [ {
      church_unit_id: "333239",
      name: "Benidorm Branch",
      city: "Benidorm",
      chapel_address: "Alfonso Puchades 27",
      country_code: "ES"
    } ])

    assert_equal "333239", demo.reload.church_unit_id
    assert_equal "RAMA", demo.code
    assert_equal "Rama Benidorm", demo.name
  end

  test "is idempotent on church_unit_id" do
    Wards::SyncDirectory.call(rows: @rows)
    before = Ward.listed.count
    stats = Wards::SyncDirectory.call(rows: @rows)

    assert_equal 0, stats[:created]
    assert_operator stats[:updated], :>=, 4
    assert_equal before, Ward.listed.count
  end

  test "does not list a self-serve create" do
    Wards::SyncDirectory.call(rows: @rows)
    extra = Wards::Create.call(name: "Rama Fork")
    assert_not extra.listed?
  end
end
