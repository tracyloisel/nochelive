require "test_helper"

class Nights::ReadingListTest < ActiveSupport::TestCase
  test "shows each scripture chapter once even when several questions cite it" do
    night = Struct.new(:quiz_packs).new([
      QuizDefinition.catalog.find_pack("exp_psalms_disappearing_voice"),
      QuizDefinition.catalog.find_pack("exp_psalms_nameless_king"),
      QuizDefinition.catalog.find_pack("exp_psalms_cry_stone_seek")
    ])

    readings = Nights::ReadingList.call(night:)

    assert_equal %w[ot/ps/102 ot/ps/103 ot/ps/110 ot/ps/116 ot/ps/117 ot/ps/118 ot/ps/119], readings.map(&:study)
  end

  test "keeps a non-scored chapter in the published reading list" do
    night = Struct.new(:quiz_packs).new([
      QuizDefinition.catalog.find_pack("exp_psalms_everything_breathes")
    ])

    assert_includes Nights::ReadingList.call(night:).map(&:study), "ot/ps/149"
  end

  test "localizes the scripture citation for the active Noche Live language" do
    night = Struct.new(:quiz_packs).new([
      QuizDefinition.catalog.find_pack("exp_psalms_disappearing_voice")
    ])

    reading = Nights::ReadingList.call(night:, locale: :es).first

    assert_equal "Salmos 102:2–12", reading.cite
  end
end
