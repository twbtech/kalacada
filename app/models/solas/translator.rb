module Solas
  class Translator < Base
    def self.count(source_language, target_language)
      active_count(source_language, target_language) + inactive_count(source_language, target_language)
    end

    def self.active_count(source_language, target_language)
      query do |connection|
        conditions = [
          'tasks_kp.claimdate IS NOT NULL',
          ("tasks_kp.langsourceid = #{source_language}" if source_language.present?),
          ("tasks_kp.langtargetid = #{target_language}" if target_language.present?)
        ].compact.join(' AND ')

        conditions = "WHERE #{conditions}"

        connection.query(
          <<-QUERY
            SELECT
              COUNT(DISTINCT users_kp.kpid) AS count
            FROM tasks_kp
              JOIN users_kp ON tasks_kp.claimuserid = users_kp.kpid
            #{conditions}
          QUERY
        ).first['count']
      end
    end

    def self.inactive_count(source_language, target_language)
      query do |connection|
        conditions = [
          ("language_id = #{source_language}" if source_language.present? && target_language.blank?),
          ("language_id = #{target_language}" if target_language.present? && source_language.blank?)
        ].compact.join(' AND ')

        q = if conditions.present?
              users_kp_conditions = conditions.gsub('language_id', 'primarylangid')

              <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, primarylangid AS language_id FROM users_kp WHERE #{users_kp_conditions}) UNION
                    (SELECT user_id, language_id FROM SolasMatch.UserSecondaryLanguages WHERE #{conditions})
                  ) AS ul1
                LEFT JOIN tasks_kp ON tasks_kp.claimuserid = ul1.user_id
                WHERE tasks_kp.claimdate IS NULL
              QUERY
            elsif source_language.present? && target_language.present?
              <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, primarylangid AS language_id FROM users_kp WHERE primarylangid = #{source_language}) UNION
                    (SELECT user_id, language_id FROM SolasMatch.UserSecondaryLanguages WHERE language_id = #{source_language})
                  ) AS ul1
                  JOIN
                  (
                    (SELECT id AS user_id, primarylangid AS language_id FROM users_kp WHERE primarylangid = #{target_language}) UNION
                    (SELECT user_id, language_id FROM SolasMatch.UserSecondaryLanguages WHERE language_id = #{target_language})
                  ) AS ul2
                  ON ul1.user_id = ul2.user_id
                LEFT JOIN tasks_kp ON tasks_kp.claimuserid = ul1.user_id
                WHERE tasks_kp.claimdate IS NULL
              QUERY
            else
              <<-QUERY
                SELECT COUNT(DISTINCT users_kp.kpid) AS count
                FROM users_kp LEFT JOIN tasks_kp ON tasks_kp.claimuserid = users_kp.kpid
                WHERE tasks_kp.claimdate IS NULL
              QUERY
            end

        connection.query(q).first['count']
      end
    end
  end
end
