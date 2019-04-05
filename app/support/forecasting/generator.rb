module Forecasting
  class Generator
    TIME_INTERVALS = { monthly: 12, weekly: 52 }.freeze

    def self.generate
      new.generate
    end

    def generate
      language_pairs.each do |lang_pair|
        TIME_INTERVALS.each do |time_interval, periods_in_a_year|
          suffix = "#{time_interval}_#{lang_pair[:source_lang_id]}_#{lang_pair[:target_lang_id]}"

          [:full, :reduced].each do |training_type|
            suffix = "#{suffix}#{'_reduced_training' if training_type == :reduced}"

            historical_data_file_path = Rails.root.join('tmp', "historical_task_count_#{suffix}.json")
            forecast_dates_file_path  = Rails.root.join('tmp', "forecast_dates_task_count_#{suffix}.json")
            forecast_data_file_path   = Rails.root.join('tmp', "forecast_task_count_#{suffix}.json")

            prepare_input_data source_lang_id:            lang_pair[:source_lang_id],
                               target_lang_id:            lang_pair[:target_lang_id],
                               historical_data_file_path: historical_data_file_path,
                               forecast_dates_file_path:  forecast_dates_file_path,
                               time_interval:             time_interval,
                               training_type:             training_type


            env_vars = [
              "HISTORICAL_DATA_PATH=#{historical_data_file_path}",
              "DATES_TO_FORECAST_PATH=#{forecast_dates_file_path}",
              "FORECAST_PATH=#{forecast_data_file_path}",
              "TIME_PERIODS_IN_A_YEAR=#{periods_in_a_year}"
            ].join(' ')

            command = [
              PYTHON_ENV_COMMAND,
              "#{env_vars} python #{Rails.root.join('app', 'forecasting', 'dnn.py')}"
            ].select(&:present?).join(' && ')

            system(command)

            post_process_output_data(forecast_data_file_path: forecast_data_file_path)
          end
        end
      end
    end

    private

    def language_pairs
      if ENV['SOURCE_LANG_ID'].present? && ENV['TARGET_LANG_ID'].present?
        [
          {
            source_lang_id: ENV['SOURCE_LANG_ID'] == 'any' ? nil : ENV['SOURCE_LANG_ID'].to_i,
            target_lang_id: ENV['TARGET_LANG_ID'] == 'any' ? nil : ENV['TARGET_LANG_ID'].to_i
          }
        ]
      else
        Solas::Language.source_languages.map(&:id).map do |source_lang_id|
          Solas::Language.target_languages.map(&:id).map do |target_lang_id|
            { source_lang_id: source_lang_id, target_lang_id: target_lang_id } if source_lang_id != target_lang_id
          end
        end.flatten.compact
      end
    end

    def prepare_input_data(options)
      raise 'Path to a file with historical datawas not provided' if options[:historical_data_file_path].blank?
      raise 'Path to a file with dates to forecast was not provided' if options[:forecast_dates_file_path].blank?
      raise "Unsupported time interval: #{options[:time_interval]}" unless TIME_INTERVALS.keys.include?(options[:time_interval])

      historical_data = Forecasting::HistoricalData.send "#{options[:time_interval]}_task_count",
                                                         options[:source_lang_id],
                                                         options[:target_lang_id]

      periods_in_year = TIME_INTERVALS[options[:time_interval]]

      if options[:training_type] == :reduced
        historical_data_reduced_training = historical_data[0..-(periods_in_year + 1)]
        File.write(options[:historical_data_file_path], historical_data_reduced_training.to_json)
      else
        File.write(options[:historical_data_file_path], historical_data.to_json)
      end

      forecast_dates  = historical_data.map { |h| h.slice(:year, :period_number) }
      latest_year     = forecast_dates.last[:year]
      forecast_dates += (forecast_dates.last[:period_number]+1..periods_in_year).map { |month| { year: latest_year, period_number: month } }

      File.write(options[:forecast_dates_file_path], forecast_dates.to_json)
    end

    def post_process_output_data(options)
      raise 'Path to a file with forecast output was not provided' if options[:forecast_data_file_path].blank?

      forecast_data = JSON.parse(File.read(options[:forecast_data_file_path]))

      forecast_data = forecast_data['year'].count.times.map do |i|
                        {
                          year:          forecast_data['year'][i.to_s],
                          period_number: forecast_data['period_number'][i.to_s],
                          value:         forecast_data['value'][i.to_s]
                        }
                      end

      File.write(options[:forecast_data_file_path], forecast_data.to_json)
    end
  end
end
