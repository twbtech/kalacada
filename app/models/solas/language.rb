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
  end
end
