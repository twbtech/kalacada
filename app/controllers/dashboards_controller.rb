class DashboardsController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.js
    end
  end

  def capacity
    respond_to(&:js)
  end

  def progress
    respond_to(&:js)
  end

  def projects
    respond_to(&:js)
  end

  private

  before_action :load_data
  def load_data
    @filter = DashboardFilter.new(params.permit(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date, :page))
    @data   = DashboardData.new(@filter)
  end

  after_action :release_db_connection
  def release_db_connection
    Solas::Connection.close
  end
end
