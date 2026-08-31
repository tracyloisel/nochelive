class AddConversationRootsAndAuthorVisibilityToScriptureCirclePosts < ActiveRecord::Migration[8.1]
  def up
    add_column :scripture_circle_posts, :conversation_root_id, :bigint
    add_column :scripture_circle_posts, :author_visibility, :string, null: false, default: "named"
    add_column :scripture_circle_post_revisions, :author_visibility, :string, null: false, default: "named"

    add_check_constraint :scripture_circle_posts,
      "author_visibility IN ('named', 'anonymous_to_ward')",
      name: "scripture_circle_posts_author_visibility"
    add_check_constraint :scripture_circle_post_revisions,
      "author_visibility IN ('named', 'anonymous_to_ward')",
      name: "scripture_circle_revisions_author_visibility"

    execute <<~SQL.squish
      UPDATE scripture_circle_posts
      SET author_visibility = CASE
        WHEN anonymous AND parent_id IS NULL AND kind = 'question' THEN 'anonymous_to_ward'
        ELSE 'named'
      END
    SQL
    execute <<~SQL.squish
      UPDATE scripture_circle_post_revisions AS revision
      SET author_visibility = CASE
        WHEN revision.anonymous AND post.parent_id IS NULL AND post.kind = 'question' THEN 'anonymous_to_ward'
        ELSE 'named'
      END
      FROM scripture_circle_posts AS post
      WHERE post.id = revision.scripture_circle_post_id
    SQL
    execute <<~SQL.squish
      UPDATE scripture_circle_posts
      SET anonymous = (author_visibility = 'anonymous_to_ward')
    SQL
    execute <<~SQL.squish
      UPDATE scripture_circle_post_revisions
      SET anonymous = (author_visibility = 'anonymous_to_ward')
    SQL
    add_check_constraint :scripture_circle_posts,
      "author_visibility <> 'anonymous_to_ward' OR (parent_id IS NULL AND kind = 'question')",
      name: "scripture_circle_posts_anonymous_questions"
    # The old boolean is retained solely as a compatibility mirror. Once its
    # legacy values have been copied into the semantic column, new raw rows
    # must not inherit anonymous visibility by default.
    change_column_default :scripture_circle_posts, :anonymous, from: true, to: false
    change_column_default :scripture_circle_post_revisions, :anonymous, from: true, to: false

    invalid_parent_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM scripture_circle_posts AS child
      JOIN scripture_circle_posts AS parent ON parent.id = child.parent_id
      WHERE child.ward_id <> parent.ward_id
         OR child.scripture_circle_thread_id <> parent.scripture_circle_thread_id
    SQL
    raise ActiveRecord::MigrationError, "Scripture Circle parent rows cross a ward or thread" if invalid_parent_count.positive?

    execute <<~SQL.squish
      WITH RECURSIVE conversation_tree AS (
        SELECT post.id, post.id AS root_id, ARRAY[post.id] AS path
        FROM scripture_circle_posts AS post
        WHERE post.parent_id IS NULL

        UNION ALL

        SELECT child.id, conversation_tree.root_id, conversation_tree.path || child.id
        FROM scripture_circle_posts AS child
        INNER JOIN conversation_tree ON child.parent_id = conversation_tree.id
        WHERE NOT (child.id = ANY(conversation_tree.path))
      )
      UPDATE scripture_circle_posts AS post
      SET conversation_root_id = conversation_tree.root_id
      FROM conversation_tree
      WHERE post.id = conversation_tree.id
        AND post.conversation_root_id IS NULL
    SQL

    unresolved_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM scripture_circle_posts
      WHERE conversation_root_id IS NULL
    SQL
    if unresolved_count.positive?
      raise ActiveRecord::MigrationError,
        "Scripture Circle posts contain a parent cycle or an unresolved conversation root"
    end

    invalid_root_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM scripture_circle_posts AS post
      INNER JOIN scripture_circle_posts AS root ON root.id = post.conversation_root_id
      LEFT JOIN scripture_circle_posts AS parent ON parent.id = post.parent_id
      WHERE root.parent_id IS NOT NULL
         OR root.ward_id <> post.ward_id
         OR root.scripture_circle_thread_id <> post.scripture_circle_thread_id
         OR (post.parent_id IS NULL AND post.conversation_root_id <> post.id)
         OR (post.parent_id IS NOT NULL AND post.conversation_root_id <> parent.conversation_root_id)
    SQL
    raise ActiveRecord::MigrationError, "Scripture Circle conversation roots are inconsistent" if invalid_root_count.positive?

    add_foreign_key :scripture_circle_posts, :scripture_circle_posts,
      column: :conversation_root_id, on_delete: :cascade
    add_index :scripture_circle_posts, [ :ward_id, :conversation_root_id, :created_at ],
      where: "status = 'visible'",
      name: "index_circle_visible_conversation_activity"
    add_index :scripture_circle_posts, [ :ward_id, :kind, :created_at ],
      where: "status = 'visible' AND parent_id IS NULL",
      name: "index_circle_visible_roots"
    add_index :scripture_circle_posts, [ :person_id, :ward_id, :conversation_root_id ],
      where: "status = 'visible'",
      name: "index_circle_visible_person_conversations"
  end

  def down
    remove_index :scripture_circle_posts, name: "index_circle_visible_person_conversations"
    remove_index :scripture_circle_posts, name: "index_circle_visible_roots"
    remove_index :scripture_circle_posts, name: "index_circle_visible_conversation_activity"
    remove_foreign_key :scripture_circle_posts, column: :conversation_root_id
    remove_check_constraint :scripture_circle_posts, name: "scripture_circle_posts_anonymous_questions"
    remove_check_constraint :scripture_circle_post_revisions, name: "scripture_circle_revisions_author_visibility"
    remove_check_constraint :scripture_circle_posts, name: "scripture_circle_posts_author_visibility"
    change_column_default :scripture_circle_post_revisions, :anonymous, from: false, to: true
    change_column_default :scripture_circle_posts, :anonymous, from: false, to: true
    remove_column :scripture_circle_post_revisions, :author_visibility
    remove_column :scripture_circle_posts, :author_visibility
    remove_column :scripture_circle_posts, :conversation_root_id
  end
end
