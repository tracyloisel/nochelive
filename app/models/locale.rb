class Locale
  AVAILABLE = %w[es pt-BR fr en].freeze
  DEFAULT = "es"
  COOKIE = :noche_locale
  FLAG = {
    "es" => "flag-es",
    "pt-BR" => "flag-pt",
    "fr" => "flag-fr",
    "en" => "flag-en"
  }.freeze

  def self.cast(value)
    raw = value.to_s.strip.tr("_", "-")
    return "pt-BR" if raw.casecmp("pt").zero? || raw.downcase.start_with?("pt-")
    return raw if AVAILABLE.include?(raw)

    AVAILABLE.find { |code| code.split("-").first == raw.split("-").first } || DEFAULT
  end

  def self.i18n(value)
    cast(value).to_sym
  end

  def self.flag(value)
    FLAG.fetch(cast(value))
  end

  def self.from_accept_language(header)
    header.to_s.split(",").each do |part|
      tag = part.split(";").first.to_s.strip
      next if tag.blank?

      code = cast(tag)
      return code if AVAILABLE.include?(code) && (
        tag.downcase.start_with?("es") ||
        tag.downcase.start_with?("pt") ||
        tag.downcase.start_with?("fr") ||
        tag.downcase.start_with?("en")
      )
    end
    DEFAULT
  end
end
