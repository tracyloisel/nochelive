class PublishPsalmsExpeditionForBenidorm < ActiveRecord::Migration[8.0]
  def up
    return unless Rails.env.production?

    load Rails.root.join("script/publish_psalms_expedition_local.rb").to_s
  end

  def down
    # Published study progress and Live scores must survive a code rollback.
  end
end
