class UpdateCalendarsJob < ApplicationJob
  queue_as :default

  def perform()
    Notebook.find_each do |current_notebook|
      current_notebook.calendar_imports.find_each do |ci|
        CalendarImporter.new(ci).perform!
      end

      ScheduleEntryMaker.new(current_notebook).perform
    end
  end
end
