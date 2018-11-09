class DashboardsController < ApplicationController
  before_action do
    @filter = DashboardFilter.new(params.permit(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date, :page))
    @data   = DashboardData.new(@filter)
  end

  def index
    respond_to do |format|
      format.html
      format.js
    end
  end

  def projects
    respond_to(&:js)
  end
end
