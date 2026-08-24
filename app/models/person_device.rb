class PersonDevice < ApplicationRecord
  belongs_to :person

  validates :device_token, presence: true
  validates :person_id, uniqueness: { scope: :device_token }
end
