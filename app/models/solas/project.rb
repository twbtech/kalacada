module Solas
  class Project < Base
    def self.count(params, options = {})
      source_language = params[:source_lang]
      target_language = params[:target_lang]
      organisation_id = params[:partner]
      project_manager = params[:project_manager]
      from_date       = params[:from_date]
      to_date         = params[:to_date]

      query do |connection|
        conditions = [
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
            SELECT COUNT(DISTINCT project_id) AS count
            FROM (
              SELECT DISTINCT Tasks.id, Tasks.project_id AS project_id
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

    def self.in_progress_count(params)
      count(params, conditions: 'Tasks.`task-status_id` = 3')
    end

    def self.not_claimed_yet_count(params)
      count(params, conditions: 'Tasks.`task-status_id` < 3')
    end

    def self.overdue_count(params)
      count(params, conditions: 'Tasks.`task-status_id` <> 4 AND Tasks.deadline < now()')
    end

    def self.projects(params, page)
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

        conditions = "WHERE #{conditions}" if conditions.present?

        q = <<-QUERY
          SELECT
            DISTINCT Projects.*,
            Tasks.`language_id-source`,
            Tasks.`language_id-target`,
            SUM(Tasks.`word-count`) AS word_count,
            MIN(Tasks.`task-status_id`) AS min_status,
            MAX(Tasks.`task-status_id`) AS max_status,
            MIN(Tasks.deadline) AS task_deadline
          FROM Tasks
            JOIN Projects ON Tasks.project_id = Projects.id
            JOIN Organisations ON Projects.organisation_id = Organisations.id
            LEFT JOIN Admins ON Organisations.id = Admins.organisation_id
            LEFT JOIN Users ON Admins.user_id = Users.id
          #{conditions}
          GROUP BY Projects.id, Tasks.`language_id-source`, Tasks.`language_id-target`
          LIMIT 20 OFFSET #{(page - 1) * 20}
        QUERY

        connection.query(q).to_a.map do |r|
          new id:                 r['id'],
              title:              r['title'],
              created_at:         r['created'],
              deadline:           r['task_deadline'],
              word_count:         r['word_count'],
              organization_id:    r['organisation_id'],
              source_language_id: r['language_id-source'],
              target_language_id: r['language_id-target'],
              min_status:         r['min_status'],
              max_status:         r['max_status']
        end
      end
    end

    def partner
      Solas::Partner.all.find { |p| p.id == organization_id }
    end

    def url
      "https://trommons.org/project/#{id}/view/"
    end

    def source_language
      Solas::Language.source_languages.find { |l| l.id == source_language_id }
    end

    def target_language
      Solas::Language.target_languages.find { |l| l.id == target_language_id }
    end

    def status
      if max_status == Solas::Task::STATUS_WAITING_PRE_REQS
        :waiting_pre_reqs
      elsif max_status == Solas::Task::STATUS_PENDING_CLAIM
        :pending_claim
      elsif max_status >= Solas::Task::STATUS_IN_PROGRESS && min_status < Solas::Task::STATUS_COMPLETE
        :in_progress
      else
        :complete
      end
    end
  end
end
