require 'spec_helper'

describe Solas::ProjectManager do
  describe 'self.source_languages' do
    it 'should execute correct SQL statement and return correct language objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
          SELECT DISTINCT users_kp.kpid, users_kp.name
          FROM users_kp
            JOIN SolasMatch.Admins ON users_kp.kpid = SolasMatch.Admins.user_id
          WHERE SolasMatch.Admins.user_id IN (SELECT user_id FROM SolasMatch.Admins WHERE organisation_id IS NULL) AND SolasMatch.Admins.organisation_id IS NOT NULL
          ORDER BY users_kp.name ASC
        QUERY
      ).and_return(
        [
          { 'id' => 1, 'name' => 'English' },
          { 'id' => 2, 'name' => 'German' }
        ]
      )

      partners = Solas::ProjectManager.all
      expect(partners.map(&:id)).to eq [1, 2]
      expect(partners.map(&:name)).to eq %w[English German]
    end
  end
end
