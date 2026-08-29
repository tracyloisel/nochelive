module Frontend
  class MediaManifest
    PATH = Rails.root.join("config/media/generated_manifest.json")

    def self.fetch(key)
      data.fetch("assets", {})[key.to_s]
    end

    def self.fetch_source(path)
      return if path.blank?

      source_index[source_stem(path)]
    end

    def self.fetch_path(path)
      return if path.blank?

      fetch_source(path) || path_index[normalize(path)]
    end

    def self.data
      @data ||= PATH.file? ? JSON.parse(PATH.read) : { "assets" => {} }
    end

    def self.reset!
      @data = nil
      @source_index = nil
      @path_index = nil
    end


    def self.source_index
      @source_index ||= data.fetch("assets", {}).values.index_by { |asset| source_stem(asset.fetch("source")) }
    end
    private_class_method :source_index

    def self.path_index
      @path_index ||= data.fetch("assets", {}).values.each_with_object({}) do |asset, index|
        asset.fetch("renditions", {}).each_value do |rendition|
          rendition.fetch("variants", {}).each_value do |variants|
            variants.each { |variant| index[normalize(variant.fetch("src"))] = asset }
          end
        end
      end
    end
    private_class_method :path_index

    def self.source_stem(path)
      normalize(path).sub(/\.(?:jpe?g|png|webp)\z/i, "")
    end
    private_class_method :source_stem

    def self.normalize(path)
      path.to_s.split(/[?#]/, 2).first.delete_prefix("/")
    end
    private_class_method :normalize
  end
end
