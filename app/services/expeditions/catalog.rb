module Expeditions
  class Catalog
    def self.call(world: nil, person: nil, locale: I18n.locale, at: Time.current)
      StudyQuizVersion
        .includes(:study_unit)
        .where(status: "published")
        .order(published_at: :desc, id: :desc)
        .filter_map do |quiz|
          Presentation.call(quiz:, world:, person:, locale:, at:)
        end
    end

    def self.find(study_unit_id:, **options)
      quiz = StudyUnit.find_by(id: study_unit_id)&.published_quiz
      Presentation.call(quiz:, **options) if quiz&.expedition?
    end
  end
end
