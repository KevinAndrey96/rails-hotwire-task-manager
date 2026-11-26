class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "Gestor de tareas <no-reply@example.com>") }
  layout "mailer"
end
