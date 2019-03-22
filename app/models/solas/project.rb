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
            SELECT COUNT(DISTINCT project_id) AS count
            FROM (
              SELECT DISTINCT tasks_kp.id, tasks_kp.project_id AS project_id
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

    def self.count_with_language_pairs(params)
      query do |connection|
        q = <<-QUERY
          SELECT COUNT(*) AS count
          FROM (
            #{projects_query(params)}
          ) AS project_list
        QUERY

        connection.query(q).to_a.first['count']
      end
    end

    def self.projects(params, page)
      query do |connection|
        q = <<-QUERY
          #{projects_query(params)}
          LIMIT 20 OFFSET #{(page - 1) * 20}
        QUERY

        connection.query(q).to_a.map do |r|
          new id:                 r['pid'],
              title:              r['title'],
              created_at:         r['createtime'],
              deadline:           r['task_deadline'],
              word_count:         r['wordcount'],
              organization_id:    r['orgid'],
              source_language_id: r['langsourceid'],
              target_language_id: r['langtargetid'],
              min_status:         r['min_status'],
              max_status:         r['max_status']
        end
      end
    end

    def self.projects_query(params)
      source_language = params[:source_lang]
      target_language = params[:target_lang]
      organisation_id = params[:partner]
      project_manager = params[:project_manager]
      from_date       = params[:from_date]
      to_date         = params[:to_date]

      conditions = [
        ("tasks_kp.langsourceid = #{source_language}" if source_language.present?),
        ("tasks_kp.langtargetid = #{target_language}" if target_language.present?),
        ("partners_kp.kpid = #{organisation_id}" if organisation_id.present?),
        ("users_kp.kpid = #{project_manager}" if project_manager.present?),
        ("tasks_kp.createdtime >= '#{from_date.to_s(:sql)}'" if from_date),
        ("tasks_kp.createdtime <= '#{to_date.to_s(:sql)}'" if to_date)
      ].compact.join(' AND ')

      conditions = "WHERE #{conditions}" if conditions.present?

      <<-QUERY
        SELECT
          DISTINCT projects_kp.pid,
          MAX(projects_kp.title) AS title,
          MAX(projects_kp.createtime) AS createtime,
          MAX(projects_kp.wordcount) AS wordcount,
          MAX(projects_kp.orgid) AS orgid,
          tasks_kp.langsourceid,
          tasks_kp.langtargetid,
          MIN(tasks_kp.taskstatusid) AS min_status,
          MAX(tasks_kp.taskstatusid) AS max_status,
          MIN(tasks_kp.deadline) AS task_deadline
        FROM tasks_kp
          JOIN projects_kp ON tasks_kp.project_id = projects_kp.pid
          JOIN partners_kp ON projects_kp.orgid = partners_kp.kpid
          LEFT JOIN Admins ON partners_kp.kpid = Admins.organisation_id
          LEFT JOIN users_kp ON Admins.user_id = users_kp.kpid
        #{conditions}
        GROUP BY projects_kp.pid, tasks_kp.langsourceid, tasks_kp.langtargetid
      QUERY
    end

    def partner
      Solas::Partner.find(organization_id)
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
