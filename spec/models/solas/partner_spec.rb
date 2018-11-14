require 'spec_helper'

describe Solas::Partner do
  before { allow(Rails.cache).to receive(:fetch).and_yield }

  describe 'self.source_languages' do
    it 'should execute correct SQL statement and return correct language objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT DISTINCT Organisations.*
            FROM Organisations
              JOIN Projects ON Organisations.id = Projects.organisation_id
            ORDER BY Organisations.name ASC
        QUERY
      ).and_return(
        [
          { 'id' => 1, 'name' => 'English' },
          { 'id' => 2, 'name' => 'German' }
        ]
      )

      partners = Solas::Partner.all
      expect(partners.map(&:id)).to eq [1, 2]
      expect(partners.map(&:name)).to eq %w[English German]
    end
  end
end
