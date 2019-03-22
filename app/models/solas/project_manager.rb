module Solas
  class ProjectManager < Base
    def self.all
      query do |connection|
        q = <<-QUERY
          SELECT DISTINCT users_kp.kpid, users_kp.name
          FROM users_kp
            JOIN Admins ON users_kp.kpid = Admins.user_id
          WHERE Admins.user_id IN (SELECT user_id FROM Admins WHERE organisation_id IS NULL) AND Admins.organisation_id IS NOT NULL
          ORDER BY users_kp.name ASC
        QUERY

        connection.query(q).to_a.map do |r|
          new id: r['kpid'], name: r['name']
        end
      end
    end
  end
end
