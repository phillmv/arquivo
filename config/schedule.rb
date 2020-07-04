# lol what production environment? dev for now pls
set :environment, "development"
every :hour do
  runner "UpdateCalendarsJob.perform_now"
end
