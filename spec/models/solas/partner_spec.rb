require 'spec_helper'

describe Solas::Partner do
  describe 'self.all' do
    it 'should execute correct SQL statement and return correct partner objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT DISTINCT partners_kp.*
            FROM partners_kp
              JOIN projects_kp ON partners_kp.kpid = projects_kp.orgid
            ORDER BY partners_kp.name ASC
        QUERY
      ).and_return(
        [
          { 'kpid' => 1, 'name' => 'Partner Inc.' },
          { 'kpid' => 2, 'name' => 'Another partner Ltd.' }
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
        'SELECT partners_kp.* FROM partners_kp WHERE partners_kp.kpid = 1'
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
