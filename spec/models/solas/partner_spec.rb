require 'spec_helper'

describe Solas::Partner do
  describe 'self.all' do
    it 'should execute correct SQL statement and return correct partner objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT DISTINCT Organisations.*
            FROM Organisations
              JOIN Projects ON Organisations.id = Projects.organisation_id
            ORDER BY Organisations.name ASC
        QUERY
      ).and_return(
        [
          { 'id' => 1, 'name' => 'Partner Inc.' },
          { 'id' => 2, 'name' => 'Another partner Ltd.' }
        ]
      )

      partners = Solas::Partner.all
      expect(partners.map(&:id)).to eq [1, 2]
      expect(partners.map(&:name)).to eq ['Partner Inc.', 'Another partner Ltd.']
    end
  end

  describe 'self.find' do
    it 'should execute correct SQL statement and return a parner object' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        'SELECT Organisations.* FROM Organisations WHERE Organisations.id = 1'
      ).and_return(
        [
          { 'id' => 1, 'name' => 'Partner Inc.' }
        ]
      )

      partner = Solas::Partner.find 1
      expect(partner.id).to eq 1
      expect(partner.name).to eq 'Partner Inc.'
    end
  end
end
