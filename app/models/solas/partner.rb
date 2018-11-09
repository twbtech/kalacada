module Solas
  class Partner < Base
    def self.all
      query do |connection|
        q = <<-QUERY
          SELECT DISTINCT Organisations.*
          FROM Organisations
            JOIN Projects ON Organisations.id = Projects.organisation_id
          ORDER BY Organisations.name ASC
        QUERY

        connection.query(q).to_a.map do |r|
          new id: r['id'], name: r['name']
        end
      end
    end
  end
end
