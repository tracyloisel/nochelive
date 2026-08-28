namespace :notifications do
  desc "Generate local VAPID keys without printing them"
  task generate_vapid: :environment do
    path = Rails.root.join(".env")
    lines = path.exist? ? path.readlines(chomp: true) : []
    existing = lines.filter_map do |line|
      key, value = line.split("=", 2)
      [ key, value ] if key.present?
    end.to_h
    next if existing["VAPID_PUBLIC_KEY"].present? && existing["VAPID_PRIVATE_KEY"].present?

    key = WebPush.generate_key
    replacements = {
      "WEB_PUSH_ENABLED" => existing.fetch("WEB_PUSH_ENABLED", "false"),
      "VAPID_PUBLIC_KEY" => key.public_key,
      "VAPID_PRIVATE_KEY" => key.private_key,
      "VAPID_SUBJECT" => existing["VAPID_SUBJECT"].presence || "mailto:tracy.loisel@gmail.com"
    }
    kept = lines.reject { |line| replacements.keys.any? { |name| line.start_with?("#{name}=") } }
    path.write((kept + replacements.map { |name, value| "#{name}=#{value}" }).join("\n") + "\n")
    File.chmod(0o600, path)
  end
end
