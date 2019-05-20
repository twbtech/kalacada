module Solas
  class Package < Base
    def self.find_packages(partner_kp_id)
      Rails.cache.fetch("Solas::Package::find_package_#{partner_kp_id}", expires_in: 1.minute) do
        query do |connection|
          result = connection.query("SELECT * FROM partners_neon JOIN partners_kp ON partners_neon.neonid = partners_kp.neonid WHERE kpid = #{partner_kp_id.to_i}").to_a

          result.map do |r|
            words_remaining = count_remaining_words partner_kp_id,
                                                    r['wordcountlimit'],
                                                    r['membrstartdate'],
                                                    r['membrexpiredate']

            new partner_division_name: r['organization'],
                word_count_limit:      r['wordcountlimit'],
                membership_name:       r['membrname'],
                member_start_date:     r['membrstartdate'],
                member_expire_date:    r['membrexpiredate'],
                partner_name:          r['partners_neon.name'],
                words_remaining:       words_remaining
          end
        end
      end
    end

    def self.count_remaining_words(partner_kp_id, max_words_count, start_date, expiration_date)
      cache_key = "Solas::Package::count_remaining_words_#{partner_kp_id}_#{start_date}_#{expiration_date}"

      words_count = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
        query do |connection|
          from = start_date.at_beginning_of_day.to_s(:db)
          to   = expiration_date.at_end_of_day.to_s(:db)

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

      [max_words_count - words_count, 0].max
    end
  end
end
