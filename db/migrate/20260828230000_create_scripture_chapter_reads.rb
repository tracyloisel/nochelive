class CreateScriptureChapterReads < ActiveRecord::Migration[8.1]
  def change
    create_table :scripture_chapter_reads do |t|
      t.references :person, foreign_key: true
      t.string :reference, null: false
      t.string :reader_digest, null: false
      t.string :locale, null: false
      t.date :read_on, null: false
      t.timestamps
    end

    add_index :scripture_chapter_reads,
      [ :reference, :reader_digest, :read_on ],
      unique: true,
      name: "index_scripture_reads_on_reference_reader_day"
    add_index :scripture_chapter_reads, [ :reference, :created_at ]

    create_table :scripture_chapter_stats do |t|
      t.string :reference, null: false
      t.bigint :reads_count, null: false, default: 0
      t.datetime :last_read_at
      t.timestamps
    end

    add_index :scripture_chapter_stats, :reference, unique: true
    add_index :scripture_chapter_stats, [ :reads_count, :reference ]
  end
end
