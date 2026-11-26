# Demo data for local environments. The password comes from DEMO_PASSWORD so no credential lives in the repository.
password = ENV["DEMO_PASSWORD"]

if password.blank?
  puts "DEMO_PASSWORD is not set, skipping demo data"
  return
end

user = User.find_or_initialize_by(email_address: ENV.fetch("DEMO_EMAIL", "demo@example.com"))
user.update!(password: password, password_confirmation: password)

today = Date.current

{
  "Lanzamiento del sitio web" => {
    description: "Sitio corporativo, dominio y campaña de lanzamiento.",
    tasks: [
      { title: "Configurar DNS y certificados TLS", priority: :high, due_on: today - 2 },
      { title: "Redactar los textos de la portada", priority: :normal, due_on: today + 3, notes: "Validar el tono con marketing." },
      { title: "Escribir el post de lanzamiento", priority: :high },
      { title: "Aprobar el logo final", priority: :low, completed_at: 2.days.ago },
      { title: "Comprar el dominio", priority: :high, completed_at: 5.days.ago }
    ]
  },
  "Mudanza de oficina" => {
    description: "Traslado del equipo a la nueva sede.",
    tasks: [
      { title: "Cotizar empresas de mudanza", priority: :normal, due_on: today + 7 },
      { title: "Inventario de equipos", priority: :low, due_on: today + 10 }
    ]
  },
  "Aprender Hotwire" => {
    description: "Turbo Drive, Frames, Streams y Stimulus.",
    tasks: [
      { title: "Leer la guía de Turbo 8 morphing", priority: :normal, completed_at: 1.day.ago },
      { title: "Practicar Turbo Streams con broadcasts", priority: :high, due_on: today + 1 }
    ]
  }
}.each do |name, attributes|
  project = user.projects.find_or_create_by!(name: name) { |p| p.description = attributes[:description] }

  attributes[:tasks].each do |task|
    project.tasks.find_or_create_by!(title: task[:title]) { |t| t.assign_attributes(task.except(:title)) }
  end
end

puts "Demo data ready for #{user.email_address}"
