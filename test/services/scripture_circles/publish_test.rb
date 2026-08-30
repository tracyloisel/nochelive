require "test_helper"

class ScriptureCircles::PublishTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @first_person = people(:carmen_garcia)
    @second_person = people(:carmen_lopez)
  end

  test "reuses the ward chapter thread for later publications" do
    first = ScriptureCircles::Publish.call(
      person: @first_person, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Première parole courte." }
    )
    second = ScriptureCircles::Publish.call(
      person: @second_person, reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Quelle lumière gardons-nous ensemble ?" }
    )

    assert_equal first.scripture_circle_thread_id, second.scripture_circle_thread_id
    assert_equal 1, @ward.scripture_circle_threads.where(reference: "ot/ps/52").count
    assert_predicate first, :anonymous?

    signed = ScriptureCircles::Publish.call(
      person: @first_person, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Je peux choisir de signer ce message.", anonymous: false }
    )
    assert_not signed.anonymous?
  end
end
