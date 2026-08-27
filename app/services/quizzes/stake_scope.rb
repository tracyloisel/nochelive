module Quizzes
  class StakeScope
    def self.wards_for(ward:)
      return Ward.listed.where(id: ward.id) if ward.stake_unit_id.blank?

      Ward.listed.where(stake_unit_id: ward.stake_unit_id)
    end

    def self.people_for(ward:)
      Person.where(ward_id: wards_for(ward:).select(:id))
    end

    def self.allowed?(challenger_ward:, opponent_ward:)
      return false unless challenger_ward && opponent_ward
      return true if challenger_ward.id == opponent_ward.id
      return false if challenger_ward.stake_unit_id.blank? || opponent_ward.stake_unit_id.blank?

      challenger_ward.stake_unit_id == opponent_ward.stake_unit_id
    end
  end
end
