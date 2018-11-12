module Solas
  class Language < Base
    def self.source_languages
      Rails.cache.fetch('Solas::Language::source_languages', expires_in: 1.minute) do
        query do |connection|
          q = <<-QUERY
            SELECT DISTINCT Languages.*
            FROM Languages
              JOIN Tasks ON Languages.id = Tasks.`language_id-source`

            ORDER BY Languages.`en-name` ASC
          QUERY

          connection.query(q).to_a.map do |r|
            new id: r['id'], name: r['en-name']
          end
        end
      end
    end

    def self.target_languages
      Rails.cache.fetch('Solas::Language::target_languages', expires_in: 1.minute) do
        query do |connection|
          q = <<-QUERY
            SELECT DISTINCT Languages.*
            FROM Languages
              JOIN Tasks ON Languages.id = Tasks.`language_id-target`

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
