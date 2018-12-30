module Solas
  class Partner < Base
    def self.all
      Rails.cache.fetch('Solas::Partner::all', expires_in: 1.minute) do
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

    def self.find(id)
      Rails.cache.fetch("Solas::Partner::find(#{id.to_i})", expires_in: 1.minute) do
        query do |connection|
          r = connection.query("SELECT Organisations.* FROM Organisations WHERE Organisations.id = #{id.to_i}").first
          new id: r['id'], name: r['name']
        end
      end
    end
  end
end
