module Solas
  class Word < Base
    def self.count(params, options)
      source_language = params[:source_lang]
      target_language = params[:target_lang]
      organisation_id = params[:partner]
      project_manager = params[:project_manager]
      from_date       = params[:from_date]
      to_date         = params[:to_date]

      query do |connection|
        conditions = [
          ("Tasks.`task-type_id` = 2"), # translation tasks
          ("Tasks.`language_id-source` = #{source_language}" if source_language.present?),
          ("Tasks.`language_id-target` = #{target_language}" if target_language.present?),
          ("Organisations.id = #{organisation_id}" if organisation_id.present?),
          ("Users.id = #{project_manager}" if project_manager.present?),
          ("Tasks.`created-time` >= '#{from_date.to_s(:sql)}'" if from_date),
          ("Tasks.`created-time` <= '#{to_date.to_s(:sql)}'" if to_date)
        ].compact.join(' AND ')

        conditions = [options[:conditions], conditions].map(&:presence).compact.join(' AND ')
        conditions = "WHERE #{conditions}" if conditions.present?

        connection.query(
          <<-QUERY
            SELECT SUM(word_count) AS count
            FROM (
              SELECT DISTINCT Tasks.id, Tasks.`word-count` AS word_count
              FROM Tasks
                JOIN Projects ON Tasks.project_id = Projects.id
                JOIN Organisations ON Projects.organisation_id = Organisations.id
                LEFT JOIN Admins ON Admins.organisation_id = Organisations.id
                LEFT JOIN Users ON Admins.user_id = Users.id
                #{options[:joins]}
              #{conditions}
            ) AS wuc
          QUERY
        ).first['count'] || 0
      end
    end

    def self.completed_count(params)
      count(params, conditions: 'Tasks.`task-status_id` = 4')
    end

    def self.uncompleted_count(params)
      count(params, conditions: 'Tasks.`task-status_id` <> 4')
    end

    def self.in_progress_count(params)
      count(params, conditions: 'Tasks.`task-status_id` = 3')
    end

    def self.not_claimed_yet_count(params)
      count(params, conditions: 'Tasks.`task-status_id` < 3')
    end

    def self.overdue_count(params)
      count(params, conditions: 'Tasks.`task-status_id` <> 4 AND Tasks.deadline < now()')
    end
  end
end
