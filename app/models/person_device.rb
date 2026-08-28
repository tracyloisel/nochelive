class PersonDevice < ApplicationRecord
  belongs_to :person
  has_many :notification_prompt_states, dependent: :destroy

  validates :device_token, presence: true
  validates :person_id, uniqueness: { scope: :device_token }

  def live? = persisted? && Presences::Registry.person_online?(person_id)
end
