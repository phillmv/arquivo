class SettingsController < ApplicationController
  def index
    @new_calendar_import = CalendarImport.new
  end

  def add_calendar
    # why did I do this this is useless
  end
end