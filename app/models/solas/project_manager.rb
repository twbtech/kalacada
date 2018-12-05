module Solas
  class ProjectManager < Base
    def self.all
      query do |connection|
        q = <<-QUERY
          SELECT Users.id, Users.`display-name`
          FROM Users
            JOIN Admins ON Users.id = Admins.user_id
          WHERE Admins.organisation_id IS NULL
          ORDER BY Users.`display-name` ASC
        QUERY

        connection.query(q).to_a.map do |r|
          new id: r['id'], name: r['display-name']
        end
      end
    end
  end
end
