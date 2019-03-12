module Solas
  class Package < Base
    def self.find_package(partner_kp_id)
      Rails.cache.fetch("Solas::Package::find_package_#{partner_kp_id}", expires_in: 1.minute) do
        query do |connection|
          result = connection.query("SELECT * FROM partners_neon JOIN partners_kp ON partners_neon.neonid = partners_kp.neonid WHERE kpid = #{partner_kp_id.to_i}").first

          if result
            new word_count_limit:   result['wordcountlimit'],
                member_name:        result['membrname'],
                member_expire_date: result['membrexpiredate'],
                member_start_date:  result['membrstartdate']
          end
        end
      end
    end

    def self.find_partners_name(partner_kp_id)
      Rails.cache.fetch("Solas::Package::find_partners_name_#{partner_kp_id}", expires_in: 1.minute) do
        query do |connection|
          connection.query("SELECT name FROM partners_kp WHERE kpid = #{partner_kp_id.to_i}").first.try(:[], 'name')
        end
      end
    end

    def self.count_remaining_words(partner_kp_id, max_words_count, start_date, expired_date)
      cache_key = "Solas::Package::count_remaining_words_#{partner_kp_id}_#{start_date}_#{expired_date}"

      words_count = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
        query do |connection|
          from = start_date.at_beginning_of_day.to_s(:db)
          to   = expired_date.at_end_of_day.to_s(:db)

          q = <<-QUERY
            SELECT SUM(tasks_kp.wordcount) AS wordcount
            FROM tasks_kp
            JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
            JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
            WHERE tasks_kp.tasktype = 'Translation' AND partners_kp.kpid = #{partner_kp_id.to_i} AND
              tasks_kp.claimdate >= '#{from}' AND tasks_kp.claimdate <= '#{to}'
          QUERY

          connection.query(q).first['wordcount'].to_i
        end
      end

      max_words_count - words_count
    end
  end
end
