class ForecastingController < ApplicationController
  def show; end

  def result
    permit_params

    @components = [:word_count, :task_count].map do |what|
      Forecasting::Generator::TIME_INTERVALS.keys.map do |time_interval|
        suffix = "#{what}_#{time_interval}_#{params[:source_lang]}_#{params[:target_lang]}"

        file_name       = "forecast_#{suffix}.json"
        file_path       = Rails.root.join('data', file_name)
        forecast_result = File.exists?(file_path) ? JSON.parse(File.read(file_path)) : []

        file_name       = "historical_#{suffix}.json"
        file_path       = Rails.root.join('data', file_name)
        historical_data = File.exists?(file_path) ? JSON.parse(File.read(file_path)) : []

        # add forecast data to historical data
        historical_data += forecast_result[historical_data.length..-1]

        [
          {
            name: t("forecasting.#{what}_#{time_interval}_historical"),
            data: historical_data.map { |r| ["#{r['period_number']}/#{r['year']}", [r['value'].to_f, 0].max] },
            colors: %w[#0b0]
          }
        ]
      end
    end.flatten
  end

  private

  before_action :check_forecasting_access
  def check_forecasting_access
    head :forbidden unless logged_in_user.try(:admin?)
  end

  before_action :load_data, except: [:result]
  def load_data
    @filter = DashboardFilter.new(params.permit(:language_pair), logged_in_user)
  end

  def permit_params
    @filter = params.permit(:source_lang, :target_lang)
  end
end
