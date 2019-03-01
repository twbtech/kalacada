module Solas
  class ProjectManager < Base
    def self.all
      query do |connection|
        q = <<-QUERY
          SELECT DISTINCT users_kp.kpid, users_kp.name
          FROM users_kp
            JOIN SolasMatch.Admins ON users_kp.kpid = SolasMatch.Admins.user_id
          WHERE SolasMatch.Admins.user_id IN (SELECT user_id FROM SolasMatch.Admins WHERE organisation_id IS NULL) AND SolasMatch.Admins.organisation_id IS NOT NULL
          ORDER BY users_kp.name ASC
        QUERY

        connection.query(q).to_a.map do |r|
          new id: r['id'], name: r['name']
        end
      end
    end
  end
end
