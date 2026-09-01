require "set"

class AddPublicSlugToWards < ActiveRecord::Migration[8.1]
  SLUG_MAX = 160
  UNIT_NAME_NOISE = %w[
    ward branch rama ramo paroisse paroquia congregation congregacion congregacao
    capilla chapel meetinghouse iglesia igreja church de del do da dos das des of the
  ].freeze

  class MigrationWard < ActiveRecord::Base
    self.table_name = "wards"
  end

  def up
    add_column :wards, :public_slug, :string, limit: SLUG_MAX
    MigrationWard.reset_column_information

    used = Set.new
    MigrationWard.order(:id).find_each do |ward|
      base = normalized(ward.city.presence || ward.chapel_name.presence || ward.name.presence || ward.code)
      slug = unique_slug(ward, base, used)
      ward.update_columns(public_slug: slug)
      used << slug
    end

    change_column_null :wards, :public_slug, false
    add_index :wards, :public_slug, unique: true
  end

  def down
    remove_index :wards, :public_slug
    remove_column :wards, :public_slug
  end

  private

    def unique_slug(ward, base, used)
      candidates = [
        base,
        compound_slug(base, unit_qualifier(ward.name, base)),
        compound_slug(base, unit_qualifier(ward.chapel_name, base)),
        compound_slug(base, ward.code),
        compound_slug(base, ward.id)
      ].compact.uniq

      candidates.find { |candidate| !used.include?(candidate) } || begin
        suffix = 2
        suffix += 1 while used.include?(compound_slug(base, suffix))
        compound_slug(base, suffix)
      end
    end

    def unit_qualifier(value, base)
      tokens = normalized(value).split("-").reject { |token| UNIT_NAME_NOISE.include?(token) }
      base_tokens = base.split("-")
      tokens = tokens.drop(base_tokens.length) if tokens.first(base_tokens.length) == base_tokens
      tokens.join("-").presence
    end

    def compound_slug(base, suffix)
      return if suffix.blank?

      normalized_suffix = normalized(suffix)

      base_limit = SLUG_MAX - normalized_suffix.length - 1
      return normalized_suffix.first(SLUG_MAX) unless base_limit.positive?

      trimmed_base = base.first(base_limit).sub(/-+\z/, "")
      normalized([ trimmed_base, normalized_suffix ].compact_blank.join("-"))
    end

    def normalized(value)
      value.to_s.parameterize.first(SLUG_MAX).sub(/-+\z/, "").presence || "rama"
    end
end
