module Solas
  class Language < Base
    def self.source_languages(logged_in_user = nil)
      if logged_in_user.try(:partner?)
        query do |connection|
          q = <<-QUERY
            SELECT DISTINCT Languages.*
            FROM Languages
              JOIN tasks_kp ON Languages.id = tasks_kp.langsourceid
              JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
            WHERE projects_kp.orgid = #{logged_in_user.partner_organization.id}
            ORDER BY Languages.`en-name` ASC
          QUERY

          connection.query(q).to_a.map do |r|
            new id: r['id'], name: r['en-name']
          end
        end
      else
        Rails.cache.fetch('Solas::Language::source_languages', expires_in: 1.minute) do
          query do |connection|
            q = <<-QUERY
            SELECT DISTINCT Languages.*
            FROM Languages
              JOIN tasks_kp ON Languages.id = tasks_kp.langsourceid

            ORDER BY Languages.`en-name` ASC
            QUERY

            connection.query(q).to_a.map do |r|
              new id: r['id'], name: r['en-name']
            end
          end
        end
      end
    end

    def self.target_languages(logged_in_user = nil)
      if logged_in_user.try(:partner?)
        query do |connection|
          q = <<-QUERY
              SELECT DISTINCT Languages.*
              FROM Languages
                JOIN tasks_kp ON Languages.id = tasks_kp.langtargetid
                JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
              WHERE projects_kp.orgid = #{logged_in_user.partner_organization.id}
              ORDER BY Languages.`en-name` ASC
          QUERY

          connection.query(q).to_a.map do |r|
            new id: r['id'], name: r['en-name']
          end
        end
      else
        Rails.cache.fetch('Solas::Language::target_languages', expires_in: 1.minute) do
          query do |connection|
            q = <<-QUERY
              SELECT DISTINCT Languages.*
              FROM Languages
                JOIN tasks_kp ON Languages.id = tasks_kp.langtargetid

              ORDER BY Languages.`en-name` ASC
            QUERY

            connection.query(q).to_a.map do |r|
              new id: r['id'], name: r['en-name']
            end
          end
        end
      end
    end

    def self.most_translated_pairs(count)
      query do |connection|
        q = <<-QUERY
          SELECT DISTINCT tasks_kp.langsourceid, l1.`en-name` AS source_language_name, tasks_kp.langtargetid, l2.`en-name` AS target_language_name, SUM(tasks_kp.wordcount) AS wordcount
            FROM tasks_kp
            JOIN Languages AS l1 ON l1.id = tasks_kp.langsourceid
            JOIN Languages AS l2 ON l2.id = tasks_kp.langtargetid
          GROUP BY tasks_kp.langsourceid, tasks_kp.langtargetid
          ORDER BY wordcount DESC
          LIMIT #{count.to_i}
        QUERY

        result = connection.query(q).to_a.map do |r|
          {
            source_lang_id:   r['langsourceid'],
            source_lang_name: r['source_language_name'],
            target_lang_id:   r['langtargetid'],
            target_lang_name: r['target_language_name'],
            word_count:       r['wordcount']
          }
        end

        result.sort_by { |lp| "#{lp[:source_lang_name]}_#{lp[:target_lang_name]}" }
      end
    end
  end
end
