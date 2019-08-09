module Forecasting
  class HistoricalData < ::Solas::Base
    START_YEAR = 2014

    def self.monthly_task_count(source_lang = nil, target_lang = nil)
      months_in_years(START_YEAR).map do |time_period|
        task_count_for_time_period(time_period, :created_time, source_lang, target_lang) do |task_count|
          { year: time_period[:from].year, period_number: time_period[:from].month, value: task_count.to_i }
        end
      end.compact
    end

    def self.task_count_for_time_period(time_period, filter_type, source_lang = nil, target_lang = nil)
      conditions = if filter_type == :created_time
                     "createdate >= '#{time_period[:from].to_s(:db)}' AND createdate <= '#{time_period[:to].to_s(:db)}'"
                   elsif filter_type == :created_until_end_time
                     "createdate <= '#{time_period[:to].to_s(:db)}' AND enddate >= '#{time_period[:from].to_s(:db)}'"
                   else
                     raise "Unsupported filter type: #{filter_type}"
                   end

      source_lang_name = (Solas::Language.find(source_lang).name if source_lang.present?)
      target_lang_name = (Solas::Language.find(target_lang).name if target_lang.present?)

      lang = if source_lang_name.present? && target_lang_name.present?
               "langsource = '#{source_lang_name}' AND langtarget = '#{target_lang_name}' AND"
             elsif source_lang_name.present?
               "langsource = '#{source_lang_name}' AND"
             elsif target_lang.present?
               "langtarget = '#{target_lang}' AND"
             end

      query do |connection|
        task_count = connection.query("SELECT COUNT(*) FROM tasks_comb WHERE #{lang} #{conditions}").to_a.first['COUNT(*)']
        yield(task_count) if time_period[:from] < Time.current
      end
    end

    def self.monthly_word_count(source_lang = nil, target_lang = nil)
      months_in_years(START_YEAR).map do |time_period|
        word_count_for_time_period(time_period, :created_time, source_lang, target_lang) do |word_count|
          { year: time_period[:from].year, period_number: time_period[:from].month, value: word_count.to_i }
        end
      end.compact
    end

    def self.word_count_for_time_period(time_period, filter_type, source_lang = nil, target_lang = nil)
      conditions = if filter_type == :created_time
                     "createdate >= '#{time_period[:from].to_s(:db)}' AND createdate <= '#{time_period[:to].to_s(:db)}'"
                   elsif filter_type == :created_until_end_time
                     "createdate <= '#{time_period[:to].to_s(:db)}' AND enddate >= '#{time_period[:from].to_s(:db)}'"
                   else
                     raise "Unsupported filter type: #{filter_type}"
                   end

      source_lang_name = (Solas::Language.find(source_lang).name if source_lang.present?)
      target_lang_name = (Solas::Language.find(target_lang).name if target_lang.present?)

      lang = if source_lang_name.present? && target_lang_name.present?
               "langsource = '#{source_lang_name}' AND langtarget = '#{target_lang_name}' AND"
             elsif source_lang_name.present?
               "langsource = '#{source_lang_name}' AND"
             elsif target_lang.present?
               "langtarget = '#{target_lang}' AND"
             end

      query do |connection|
        task_count = connection.query("SELECT SUM(wordcount) FROM tasks_comb WHERE #{lang} #{conditions}").to_a.first['SUM(wordcount)']
        yield(task_count) if time_period[:from] < Time.current
      end
    end

    def self.months_in_years(since_year)
      years = (since_year..Time.current.year)

      years.map do |year|
        (1..12).map do |month|
          from = Time.new(year, month, 1, 12).utc.at_beginning_of_month
          { from: from, to: from.at_end_of_month } if from < Time.current.at_beginning_of_month
        end
      end.flatten.compact
    end

    def self.weeks_in_years(since_year)
      years = (since_year..Time.current.year)

      years.map do |year|
        (1..52).map do |week|
          from = Time.new(year, 1, 1).utc + (7 * week - 1).days
          to   = from + 7.days - 1.second

          { from: from, to: to }
        end
      end.flatten
    end
  end
end
