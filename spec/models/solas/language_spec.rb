require 'spec_helper'

describe Solas::Language do
  before { allow(Rails.cache).to receive(:fetch).and_yield }

  describe 'self.source_languages' do
    it 'should execute correct SQL statement and return correct language objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT DISTINCT Languages.*
            FROM Languages
              JOIN Tasks ON Languages.id = Tasks.`language_id-source`

            ORDER BY Languages.`en-name` ASC
        QUERY
      ).and_return(
        [
          { 'id' => 1, 'en-name' => 'English' },
          { 'id' => 2, 'en-name' => 'German' }
        ]
      )

      languages = Solas::Language.source_languages
      expect(languages.map(&:id)).to eq [1, 2]
      expect(languages.map(&:name)).to eq %w[English German]
    end
  end

  describe 'self.target_languages' do
    it 'should execute correct SQL statement and return correct language objects' do
      expect_any_instance_of(Solas::Connection).to receive(:query).with(
        <<-QUERY
            SELECT DISTINCT Languages.*
            FROM Languages
              JOIN Tasks ON Languages.id = Tasks.`language_id-target`

            ORDER BY Languages.`en-name` ASC
        QUERY
      ).and_return(
        [
          { 'id' => 1, 'en-name' => 'English' },
          { 'id' => 2, 'en-name' => 'German' }
        ]
      )

      languages = Solas::Language.target_languages
      expect(languages.map(&:id)).to eq [1, 2]
      expect(languages.map(&:name)).to eq %w[English German]
    end
  end
end
