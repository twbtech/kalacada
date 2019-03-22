module Solas
  class Task < Base
    STATUS_WAITING_PRE_REQS = 1
    STATUS_PENDING_CLAIM    = 2
    STATUS_IN_PROGRESS      = 3
    STATUS_COMPLETE         = 4

    def self.count(params, options)
      source_language = params[:source_lang]
      target_language = params[:target_lang]
      organisation_id = params[:partner]
      project_manager = params[:project_manager]
      from_date       = params[:from_date]
      to_date         = params[:to_date]

      query do |connection|
        conditions = [
          ("tasks_kp.langsourceid = #{source_language}" if source_language.present?),
          ("tasks_kp.langtargetid = #{target_language}" if target_language.present?),
          ("partners_kp.kpid = #{organisation_id}" if organisation_id.present?),
          ("users_kp.kpid = #{project_manager}" if project_manager.present?),
          ("tasks_kp.createdtime >= '#{from_date.to_s(:sql)}'" if from_date),
          ("tasks_kp.createdtime <= '#{to_date.to_s(:sql)}'" if to_date)
        ].compact.join(' AND ')

        conditions = [options[:conditions], conditions].map(&:presence).compact.join(' AND ')
        conditions = "WHERE #{conditions}" if conditions.present?

        connection.query(
          <<-QUERY
            SELECT COUNT(id) AS count
            FROM (
              SELECT DISTINCT tasks_kp.id
              FROM tasks_kp
                JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
                JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
                LEFT JOIN Admins ON Admins.organisation_id = partners_kp.kpid
                LEFT JOIN users_kp ON Admins.user_id = users_kp.kpid
                #{options[:joins]}
              #{conditions}
            ) AS wuc
          QUERY
        ).first['count'] || 0
      end
    end

    def self.completed_count(params)
      count(params, conditions: 'tasks_kp.taskstatusid = 4')
    end

    def self.in_progress_count(params)
      count(params, conditions: 'tasks_kp.taskstatusid = 3')
    end

    def self.not_claimed_yet_count(params)
      count(params, conditions: 'tasks_kp.taskstatusid < 3')
    end

    def self.overdue_count(params)
      count(params, conditions: 'tasks_kp.taskstatusid <> 4 AND tasks_kp.deadline < now()')
    end
  end
end
