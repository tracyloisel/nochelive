class AddAnonymousToScriptureCirclePosts < ActiveRecord::Migration[8.1]
  def change
    add_column :scripture_circle_posts, :anonymous, :boolean, null: false, default: true
    add_column :scripture_circle_post_revisions, :anonymous, :boolean, null: false, default: true
  end
end
