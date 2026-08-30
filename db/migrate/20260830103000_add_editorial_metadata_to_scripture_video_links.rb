class AddEditorialMetadataToScriptureVideoLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :scripture_video_links, :source_url, :string
    add_column :scripture_video_links, :reviewed_by, :string
    add_column :scripture_video_links, :published_at, :datetime

    add_check_constraint :scripture_video_links,
      "status <> 'published' OR (verified_at IS NOT NULL AND published_at IS NOT NULL AND reviewed_by IS NOT NULL AND source_url IS NOT NULL)",
      name: "scripture_video_links_published_metadata"
  end
end
