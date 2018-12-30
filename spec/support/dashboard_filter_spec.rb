require 'spec_helper'

describe DashboardFilter do
  let(:params) do
    {
      source_lang:     '1; SQL INJECTION STATEMENT',
      target_lang:     '2; SQL INJECTION STATEMENT',
      partner:         '3; SQL INJECTION STATEMENT',
      project_manager: '4; SQL INJECTION STATEMENT',
      from_date:       '01.10.2018',
      to_date:         '08.10.2018',
      page:            '7; SQL INJECTION STATEMENT'
    }
  end

  let(:filter) { DashboardFilter.new params, logged_in_user }

  context 'logged_in_user is an admin' do
    let(:logged_in_user) do
      allow_any_instance_of(Solas::User).to receive(:load_role).and_return(:admin)
      Solas::User.new id: 3
    end

    [
      :source_lang,
      :target_lang,
      :partner,
      :project_manager,
      :from_date,
      :to_date,
      :page
    ].each do |attr|
      it "should respond to #{attr}" do
        expect(filter).to respond_to(attr)
      end

      describe "value of #{attr} is an empty string" do
        before { params.merge!(attr => '') }

        it "should return nil for #{attr}" do
          expect(filter.send(attr)).to be nil
        end
      end
    end

    it 'should return source_lang as integer' do
      expect(filter.source_lang).to be 1
    end

    it 'should return target_lang as integer' do
      expect(filter.target_lang).to be 2
    end

    it 'should return partner as integer' do
      expect(filter.partner).to be 3
    end

    it 'should return project_manager as integer' do
      expect(filter.project_manager).to be 4
    end

    it 'should return from_date as date' do
      expect(filter.from_date).to eq Date.new(2018, 10, 1)
    end

    it 'should return to_date as date' do
      expect(filter.to_date).to eq Date.new(2018, 10, 8)
    end

    it 'should return page as integer' do
      expect(filter.page).to be 7
    end

    describe 'to_sanitized_hash' do
      it 'should return hash with sanitized values' do
        expected_result = {
          source_lang:     1,
          target_lang:     2,
          partner:         3,
          project_manager: 4,
          from_date:       Date.new(2018, 10, 1),
          to_date:         Date.new(2018, 10, 8),
          page:            7
        }

        expect(filter.to_sanitized_hash).to eq expected_result
      end
    end
  end

  context 'logged_in_user is a partner' do
    let(:partner_organization) { Solas::Partner.new(id: 5, name: 'Partner Inc.') }

    let(:logged_in_user) do
      allow_any_instance_of(Solas::User).to receive(:load_role).and_return(:partner)
      allow_any_instance_of(Solas::User).to receive(:partner_organization).and_return(partner_organization)
      Solas::User.new id: 3
    end

    [
      :source_lang,
      :target_lang,
      :project_manager,
      :from_date,
      :to_date,
      :page
    ].each do |attr|
      it "should respond to #{attr}" do
        expect(filter).to respond_to(attr)
      end

      describe "value of #{attr} is an empty string" do
        before { params.merge!(attr => '') }

        it "should return nil for #{attr}" do
          expect(filter.send(attr)).to be nil
        end
      end
    end

    it 'should respond to partner' do
      expect(filter).to respond_to(:partner)
    end

    describe 'value of partner is an empty string' do
      before { params.merge!(partner: '') }

      it 'should return id of partner organization' do
        expect(filter.partner).to be partner_organization.id
      end
    end

    it 'should return source_lang as integer' do
      expect(filter.source_lang).to be 1
    end

    it 'should return target_lang as integer' do
      expect(filter.target_lang).to be 2
    end

    it 'should return partner as integer - loaded from a partner organization' do
      expect(filter.partner).to be partner_organization.id
    end

    it 'should return nil for project_manager filter' do
      expect(filter.project_manager).to be nil
    end

    it 'should return from_date as date' do
      expect(filter.from_date).to eq Date.new(2018, 10, 1)
    end

    it 'should return to_date as date' do
      expect(filter.to_date).to eq Date.new(2018, 10, 8)
    end

    it 'should return page as integer' do
      expect(filter.page).to be 7
    end

    describe 'to_sanitized_hash' do
      it 'should return hash with sanitized values' do
        expected_result = {
          source_lang:     1,
          target_lang:     2,
          partner:         partner_organization.id,
          project_manager: nil,
          from_date:       Date.new(2018, 10, 1),
          to_date:         Date.new(2018, 10, 8),
          page:            7
        }

        expect(filter.to_sanitized_hash).to eq expected_result
      end
    end
  end
end
