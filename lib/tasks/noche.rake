namespace :noche do
  desc "Wipe nights and quiz runs, then seed a playable DEMO"
  task reseed: :environment do
    night = Nights::Reseed.call
    abort "DEMO night missing after reseed" unless night&.live?

    puts "DEMO #{night.status} · #{night.theme_title}"
  end
end
