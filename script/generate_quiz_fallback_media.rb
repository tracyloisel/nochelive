#!/usr/bin/env ruby
# frozen_string_literal: true

# Builds local, family-safe fallback stills for the parable collection by
# remastering existing Noche Live gouaches. This keeps every quiz playable when
# the configured image API has no credit. The detailed final-generation prompts
# remain in config/media/quiz_stills.yml and can replace these files later.

require "fileutils"
require "open3"
require "yaml"

ROOT = File.expand_path("..", __dir__)
CATALOG = File.join(ROOT, "config/quizzes/parabolas.yml")
CHROME = File.join(ROOT, "config/media/quiz_stills.yml")
MEDIA = File.join(ROOT, "public/media/quizzes")

SOURCES = {
  "perdido_encontrado" => %w[
    milenio/lobo_cordero_milenio.jpg profetas/jonas_tarsis.jpg milenio/un_rebano.jpg
    hermanas/viuda_blancas.jpg milagros/aceite_viuda.jpg exaltacion/familias_selladas.jpg
    abish/saria_lehi.jpg pruebas_heroes/jose_vendido.jpg pruebas_heroes/jose_bien.jpg
    exaltacion/obra_gloria.jpg
  ],
  "secretos_reino" => %w[
    moises/eden_adan.jpg pruebas_profetas/isaias_no_oiria.jpg abraham/tierra_simiente.jpg
    coronas/vina_nabot.jpg milagros/mostaza.jpg milagros/mana_cielo.jpg
    jose/cerro_planchas.jpg kolob/urim_tumim.jpg abraham/senor_libero.jpg
    exaltacion/presencia_padre.jpg
  ],
  "amar_projimo" => %w[
    profetas/jonas_tarsis.jpg pruebas_heroes/david_huyo.jpg profetas/naaman_jordan.jpg
    milagros/aceite_viuda.jpg hermanas/abigail_david.jpg coronas/juicio_madres.jpg
    exaltacion/gracia_gracia.jpg pruebas_heroes/jose_carcel.jpg pruebas_heroes/jose_bien.jpg
    hermanas/magdalena_tumba.jpg
  ],
  "velar_servir" => %w[
    inicios/ley_kirtland.jpg jose/oliver_traduce.jpg jose/cerro_planchas.jpg
    exaltacion/gracia_gracia.jpg milenio/mil_anos_reino.jpg milagros/aceite_viuda.jpg
    nazareno/nacio_belen.jpg premortal/segundo_satanas.jpg hermanas/marta_parte.jpg
    exaltacion/obra_gloria.jpg
  ],
  "sobre_roca" => %w[
    moises/eden_adan.jpg abraham/sacerdotes_altar.jpg milagros/mar_abrio.jpg
    milagros/jerico_cayeron.jpg coronas/vina_nabot.jpg inicios/nauvoo_hermosa.jpg
    pruebas_heroes/job_no_maldijo.jpg profetas/isaias_templo.jpg jose/liberty_donde.jpg
    exaltacion/gracia_gracia.jpg
  ],
  "simbolos_mormon" => %w[
    abraham/tierra_simiente.jpg moises/eden_adan.jpg abish/saria_bronce.jpg
    pruebas_profetas/elias_jezabel.jpg milagros/mostaza.jpg jose/bosquecillo.jpg
    abish/saria_barco.jpg placas/lehi_jerusalen.jpg placas/moroni_planchas.jpg
    abish/abish_vision.jpg
  ],
  "parabolas_profetas" => %w[
    milenio/lobo_cordero_milenio.jpg pruebas_heroes/david_huyo.jpg coronas/juicio_madres.jpg
    abraham/tierra_simiente.jpg pruebas_profetas/elias_jezabel.jpg profetas/elias_cuervos.jpg
    profetas/eliseo_carros.jpg pruebas_profetas/noe_no_escucho.jpg inicios/misuri.jpg
    profetas/tres_horno.jpg
  ]
}.freeze

catalog = YAML.safe_load_file(CATALOG).fetch("packs")
stills = YAML.safe_load_file(CHROME).fetch("stills")

catalog.each do |pack|
  pack_id = pack.fetch("id")
  sources = SOURCES.fetch(pack_id)
  questions = pack.fetch("questions")
  abort "source count mismatch for #{pack_id}" unless sources.size == questions.size

  questions.each_with_index do |question, index|
    rel = question.dig("presentation", "image")
    dest = File.join(ROOT, "public/media", rel)
    next if File.exist?(dest)

    source = File.join(MEDIA, sources.fetch(index))
    abort "missing fallback source #{source}" unless File.file?(source)

    mode = stills.fetch(rel).fetch("mode")
    FileUtils.mkdir_p(File.dirname(dest))
    color = mode == "dark" ? "#061226" : "#f4ead6"
    brightness = mode == "dark" ? "82,108,100" : "106,94,100"
    tint = mode == "dark" ? "18" : "7"
    offset = ((pack_id.each_byte.sum + index * 17) % 45) - 22

    command = [
      "magick", source,
      "-auto-orient", "-resize", "1120x1995^", "-gravity", "center",
      "-crop", "1024x1824#{offset >= 0 ? '+' : ''}#{offset}+0", "+repage",
      "-modulate", brightness, "-fill", color, "-colorize", tint,
      "-contrast-stretch", "1%x1%", "-vignette", "0x24",
      "-quality", "88", dest
    ]
    _out, err, status = Open3.capture3(*command)
    abort "magick failed for #{rel}: #{err}" unless status.success?

    puts "wrote #{dest.delete_prefix("#{ROOT}/")} from #{sources.fetch(index)}"
  end
end
