class AddSelectedVersesToScriptureCirclePosts < ActiveRecord::Migration[8.1]
  def change
    add_column :scripture_circle_posts, :selected_verses, :string
    add_check_constraint :scripture_circle_posts,
      "selected_verses IS NULL OR char_length(selected_verses) <= 120",
      name: "scripture_circle_posts_selected_verses_length"
  end
end
