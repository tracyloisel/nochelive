class ReseedProductionDemo < ActiveRecord::Migration[8.1]
  def up
    return unless Rails.env.production?

    Nights::Reseed.call
  end

  def down; end
end
