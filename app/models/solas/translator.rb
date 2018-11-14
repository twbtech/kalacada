module Solas
  class Translator < Base
    def self.count(source_language, target_language)
      active_count(source_language, target_language) + inactive_count(source_language, target_language)
    end

    def self.active_count(source_language, target_language)
      query do |connection|
        conditions = [
          ("Tasks.`language_id-source` = #{source_language}" if source_language.present?),
          ("Tasks.`language_id-target` = #{target_language}" if target_language.present?)
        ].compact.join(' AND ')

        conditions = "WHERE #{conditions}" if conditions.present?

        connection.query(
          <<-QUERY
            SELECT
              COUNT(DISTINCT Users.id) AS count
            FROM Tasks
              JOIN TaskClaims ON Tasks.id = TaskClaims.task_id
              JOIN Users      ON TaskClaims.user_id = Users.id
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
              <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE #{conditions}) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE #{conditions})
                  ) AS ul1
                LEFT JOIN TaskClaims ON TaskClaims.user_id = ul1.user_id
                WHERE TaskClaims.id IS NULL
              QUERY
            elsif source_language.present? && target_language.present?
              <<-QUERY
                SELECT COUNT(DISTINCT ul1.user_id) AS count FROM
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE language_id = #{source_language}) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE language_id = #{source_language})
                  ) AS ul1
                  JOIN
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE language_id = #{target_language}) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE language_id = #{target_language})
                  ) AS ul2
                  ON ul1.user_id = ul2.user_id
                LEFT JOIN TaskClaims ON TaskClaims.user_id = ul1.user_id
                WHERE TaskClaims.id IS NULL
              QUERY
            else
              <<-QUERY
                SELECT COUNT(DISTINCT Users.id) AS count
                FROM Users LEFT JOIN TaskClaims ON TaskClaims.user_id = Users.id
                WHERE TaskClaims.id IS NULL
              QUERY
            end

        connection.query(q).first['count']
      end
    end
  end
end
