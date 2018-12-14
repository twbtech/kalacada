require 'spec_helper'

describe Solas::ProjectManager do
  describe 'self.source_languages' do
    it 'should execute correct SQL statement and return correct language objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
          SELECT DISTINCT Users.id, Users.`display-name`
          FROM Users
            JOIN Admins ON Users.id = Admins.user_id
          WHERE Admins.user_id IN (SELECT user_id FROM Admins WHERE organisation_id IS NULL) AND Admins.organisation_id IS NOT NULL
          ORDER BY Users.`display-name` ASC
        QUERY
      ).and_return(
        [
          { 'id' => 1, 'display-name' => 'English' },
          { 'id' => 2, 'display-name' => 'German' }
        ]
      )

      partners = Solas::ProjectManager.all
      expect(partners.map(&:id)).to eq [1, 2]
      expect(partners.map(&:name)).to eq %w[English German]
    end
  end
end
