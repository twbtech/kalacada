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
      query do
        conditions = [
          ("language_1_id = #{source_language}" if source_language.present?),
          ("language_2_id = #{target_language}" if target_language.present?)
        ].compact.join(' AND ')

        conditions = "AND #{conditions}" if conditions.present?

        q = if conditions.present?
              <<-QUERY
                SELECT COUNT(DISTINCT ul3.user_id) AS count FROM
                (
                  SELECT ul1.user_id, ul1.language_id AS language_1_id, ul2.language_id AS language_2_id FROM
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE language_id IS NOT NULL) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE language_id IS NOT NULL)
                  ) AS ul1
                  JOIN
                  (
                    (SELECT id AS user_id, language_id FROM Users WHERE language_id IS NOT NULL) UNION
                    (SELECT user_id, language_id FROM UserSecondaryLanguages WHERE language_id IS NOT NULL)
                  ) AS ul2
                  ON ul1.user_id = ul2.user_id
                ) AS ul3
                LEFT JOIN TaskClaims ON TaskClaims.user_id = ul3.user_id
                WHERE TaskClaims.id IS NULL #{conditions}
              QUERY
            else
              <<-QUERY
                SELECT COUNT(DISTINCT Users.id) AS count
                FROM Users LEFT JOIN TaskClaims ON TaskClaims.user_id = Users.id
                WHERE TaskClaims.id IS NULL
              QUERY
            end

        0 # connection.query(q).first['count']
      end
    end
  end
end
