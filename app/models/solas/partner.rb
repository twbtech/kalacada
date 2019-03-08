module Solas
  class Partner < Base
    def self.all
      Rails.cache.fetch('Solas::Partner::all', expires_in: 1.minute) do
        query do |connection|
          q = <<-QUERY
            SELECT DISTINCT partners_kp.*
            FROM partners_kp
              JOIN projects_kp ON partners_kp.kpid = projects_kp.orgid
            ORDER BY partners_kp.name ASC
          QUERY

          connection.query(q).to_a.map do |r|
            new id: r['kpid'], name: r['name']
          end
        end
      end
    end

    def self.find(id)
      Rails.cache.fetch("Solas::Partner::find(#{id.to_i})", expires_in: 1.minute) do
        query do |connection|
          r = connection.query("SELECT partners_kp.* FROM partners_kp WHERE partners_kp.kpid = #{id.to_i}").first
          new id: r['kpid'], name: r['name']
        end
      end
    end
  end
end
