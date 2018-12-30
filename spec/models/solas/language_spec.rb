require 'spec_helper'

describe Solas::Language do
  let(:admin_user) { double(:user, admin?: true) }

  let(:partner_organization) { double(:organization, id: 1) }
  let(:partner_user)         { double(:user, admin?: false, partner?: true, partner_organization: partner_organization) }

  describe 'self.source_languages' do
    context 'logged in user is an admin' do
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

        languages = Solas::Language.source_languages(admin_user)
        expect(languages.map(&:id)).to eq [1, 2]
        expect(languages.map(&:name)).to eq %w[English German]
      end
    end

    context 'logged in user is a partner' do
      it 'should execute correct SQL statement and return correct language objects' do
        expect_any_instance_of(Solas::Connection).to receive(:query).with(
          <<-QUERY
            SELECT DISTINCT Languages.*
            FROM Languages
              JOIN Tasks ON Languages.id = Tasks.`language_id-source`
              JOIN Projects ON Tasks.project_id = Projects.id
            WHERE Projects.organisation_id = #{partner_organization.id}
            ORDER BY Languages.`en-name` ASC
          QUERY
        ).and_return(
          [
            { 'id' => 1, 'en-name' => 'English' },
            { 'id' => 2, 'en-name' => 'German' }
          ]
        )

        languages = Solas::Language.source_languages(partner_user)
        expect(languages.map(&:id)).to eq [1, 2]
        expect(languages.map(&:name)).to eq %w[English German]
      end
    end
  end

  describe 'self.target_languages' do
    context 'logged in user is an admin' do
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

        languages = Solas::Language.target_languages(admin_user)
        expect(languages.map(&:id)).to eq [1, 2]
        expect(languages.map(&:name)).to eq %w[English German]
      end
    end

    context 'logged in user is a partner' do
      it 'should execute correct SQL statement and return correct language objects' do
        expect_any_instance_of(Solas::Connection).to receive(:query).with(
          <<-QUERY
              SELECT DISTINCT Languages.*
              FROM Languages
                JOIN Tasks ON Languages.id = Tasks.`language_id-target`
                JOIN Projects ON Tasks.project_id = Projects.id
              WHERE Projects.organisation_id = #{partner_organization.id}
              ORDER BY Languages.`en-name` ASC
          QUERY
        ).and_return(
          [
            { 'id' => 1, 'en-name' => 'English' },
            { 'id' => 2, 'en-name' => 'German' }
          ]
        )

        languages = Solas::Language.target_languages(partner_user)
        expect(languages.map(&:id)).to eq [1, 2]
        expect(languages.map(&:name)).to eq %w[English German]
      end
    end
  end
end
