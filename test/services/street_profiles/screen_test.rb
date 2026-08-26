require "test_helper"

class StreetProfiles::ScreenTest < ActiveSupport::TestCase
  setup do
    @pili = people(:pili)
    @carmen = people(:carmen_garcia)
  end

  test "create form when the device knows nobody" do
    gate = StreetProfiles::Screen.call(people_on_device: [])
    assert_equal :form, gate.name
    assert_nil gate.person
    assert_empty gate.people
  end

  test "welcome for the signed-in ficha before anyone else" do
    gate = StreetProfiles::Screen.call(
      people_on_device: [ @pili, @carmen ],
      current_person: @pili
    )
    assert_equal :welcome, gate.name
    assert_equal @pili, gate.person
  end

  test "other device fichas only after not me" do
    gate = StreetProfiles::Screen.call(
      people_on_device: [ @pili, @carmen ],
      current_person: @pili,
      not_me: true
    )
    assert_equal :device, gate.name
    assert_equal [ @carmen ], gate.people
  end

  test "create form after not me when the device holds no other ficha" do
    gate = StreetProfiles::Screen.call(
      people_on_device: [ @pili ],
      current_person: @pili,
      not_me: true
    )
    assert_equal :form, gate.name
  end

  test "fresh skips every known ficha and opens create" do
    gate = StreetProfiles::Screen.call(
      people_on_device: [ @pili, @carmen ],
      current_person: @pili,
      fresh: true
    )
    assert_equal :form, gate.name
  end

  test "unsigned device with one ficha still asks is this you" do
    gate = StreetProfiles::Screen.call(people_on_device: [ @pili ])
    assert_equal :welcome, gate.name
    assert_equal @pili, gate.person
  end

  test "unsigned device with several fichas lists them" do
    gate = StreetProfiles::Screen.call(people_on_device: [ @pili, @carmen ])
    assert_equal :device, gate.name
    assert_equal [ @pili, @carmen ], gate.people
  end

  test "claim and homonyms win over the device trail" do
    claim = StreetProfiles::Screen.call(
      people_on_device: [ @pili ],
      current_person: @pili,
      claim_person: @carmen
    )
    assert_equal :claim, claim.name
    assert_equal @carmen, claim.person

    homonyms = StreetProfiles::Screen.call(
      people_on_device: [ @pili ],
      homonyms: true
    )
    assert_equal :homonyms, homonyms.name
  end
end
