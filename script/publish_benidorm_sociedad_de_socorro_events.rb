# frozen_string_literal: true

# Publishes the four Feria de las Naciones activities for the local demo Rama.
# Safe to rerun: existing published records with the same title are preserved.

ward = Ward.find_by!(code: "RAMA")
starts_at = Time.zone.parse("2026-12-12 10:30")
ends_at = starts_at + 3.hours
actor = "Sociedad de Socorro · Rama Benidorm"

events = [
  {
    kind: "music_activity",
    title: "Actuación folclórica",
    summary: "Disfrutaremos de una tarde de música, color y tradiciones de distintos países. ¡Anímate a participar y a compartir tu cultura!",
    artwork_path: "/media/rama/events/benidorm-folklore.jpg"
  },
  {
    kind: "food_drive",
    title: "Platos típicos",
    summary: "Compartiremos platos típicos preparados con cariño. Trae una receta de tu país y celebremos juntos la diversidad de nuestra Rama.",
    artwork_path: "/media/rama/events/benidorm-food.jpg"
  },
  {
    kind: "clothing_drive",
    title: "Ropa de segunda mano",
    summary: "Dale una nueva vida a la ropa en buen estado. Trae prendas limpias para intercambiar y ayudar a otras familias de la comunidad.",
    artwork_path: "/media/rama/events/benidorm-clothing.jpg"
  },
  {
    kind: "books_and_school_supplies_drive",
    title: "Material escolar",
    summary: "Preparamos material escolar para que ningún niño empiece el curso sin lo necesario. Puedes traer cuadernos, lápices, mochilas o pinturas.",
    artwork_path: "/media/rama/events/benidorm-school-supplies.jpg"
  }
]

events.each do |attributes|
  event = ward.ward_events.find_or_initialize_by(title: attributes.fetch(:title))
  next if event.persisted? && event.published?

  if event.persisted?
    event.update_draft!(
      attributes: attributes.merge(
        starts_at:,
        ends_at:,
        location_label: "Capilla de Benidorm · Sociedad de Socorro",
        destination_path: "/ramas/RAMA",
        destination_url: nil
      ),
      actor:,
      at: Time.current
    )
  else
    event = WardEvent.create_draft!(
      ward:,
      attributes: attributes.merge(
        starts_at:,
        ends_at:,
        location_label: "Capilla de Benidorm · Sociedad de Socorro",
        destination_path: "/ramas/RAMA"
      ),
      actor:,
      at: Time.current
    )
  end

  event.publish!(actor:, at: Time.current)
end

puts "#{ward.ward_events.where(title: events.map { |event| event.fetch(:title) }).count} eventos publicados en #{ward.name}."
