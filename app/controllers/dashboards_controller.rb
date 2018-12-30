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

  before_action :check_dashboard_access
  def check_dashboard_access
    allowed_actions = if logged_in_user.try(:admin?)
                        %w[index capacity progress projects]
                      elsif logged_in_user.try(:partner?)
                        %w[index progress projects]
                      else
                        []
                      end

    render status: :forbidden unless allowed_actions.include?(action_name)
  end

  before_action :load_data
  def load_data
    @filter = DashboardFilter.new(params.permit(:source_lang, :target_lang, :partner, :project_manager, :from_date, :to_date, :page), logged_in_user)
    @data   = DashboardData.new(@filter)
  end

  after_action :release_db_connection
  def release_db_connection
    Solas::Connection.close
  end
end
