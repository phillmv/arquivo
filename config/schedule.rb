# lol what production environment? dev for now pls
set :environment, "development"
every :hour, mailto: "" do
  runner "UpdateCalendarsJob.perform_now"
end
