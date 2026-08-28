require "test_helper"

class ScriptureChapterReadTest < ActiveSupport::TestCase
  test "keeps the anonymous reading when a person is deleted" do
    person = Person.create!(given_name: "Lecteur", avatar_key: "delfin", locale: "fr")
    reading = ScriptureChapterRead.create!(
      person:,
      reference: "ot/1-sam/16",
      reader_digest: GameSession.digest_token("reader-to-delete"),
      locale: "fr",
      read_on: Date.current
    )

    person.destroy!

    assert_nil reading.reload.person_id
  end
end
