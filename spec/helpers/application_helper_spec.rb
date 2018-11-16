require 'spec_helper'

describe ApplicationHelper do
  let(:english) { Solas::Language.new id: 1, name: 'English' }
  let(:german)  { Solas::Language.new id: 2, name: 'German' }
  let(:russian) { Solas::Language.new id: 3, name: 'Russian' }

  let(:partner_1) { Solas::Partner.new id: 1, name: 'Some partner' }
  let(:partner_2) { Solas::Partner.new id: 2, name: 'Some other partner' }

  let(:project_manager_1) { Solas::ProjectManager.new id: 1, name: 'Some project manager' }
  let(:project_manager_2) { Solas::ProjectManager.new id: 2, name: 'Some other manager' }

  describe 'source_language_options_for_select' do
    it 'should return options for select of source languages' do
      expect(Solas::Language).to receive(:source_languages).and_return([english, german])
      expect(source_language_options_for_select).to eq "<option value=\"\">Any source language</option>\n<option value=\"1\">English</option>\n<option value=\"2\">German</option>"
    end
  end

  describe 'target_language_options_for_select' do
    it 'should return options for select of target languages' do
      expect(Solas::Language).to receive(:target_languages).and_return([english, russian])
      expect(target_language_options_for_select).to eq "<option value=\"\">Any target language</option>\n<option value=\"1\">English</option>\n<option value=\"3\">Russian</option>"
    end
  end

  describe 'partner_options_for_select' do
    it 'should return options for select of partners' do
      expect(Solas::Partner).to receive(:all).and_return([partner_1, partner_2])
      expect(partner_options_for_select).to eq "<option value=\"\">Any partner</option>\n<option value=\"1\">Some partner</option>\n<option value=\"2\">Some other partner</option>"
    end
  end

  describe 'project_manager_options_for_select' do
    it 'should return options for select of partners' do
      expect(Solas::ProjectManager).to receive(:all).and_return([project_manager_1, project_manager_2])
      expect(project_manager_options_for_select).to eq "<option value=\"\">Any project manager</option>\n<option value=\"1\">Some project manager</option>\n<option value=\"2\">Some other manager</option>"
    end
  end

  xdescribe 'paging' do
    it 'should correct return links to pages when first page is active' do
      expect(paging(1, 6)).to eq ''
    end

    it 'should correct return links to pages when third page is active' do
      expect(paging(3, 6)).to eq ''
    end

    it 'should correct return links to pages when fifth page is active' do
      expect(paging(5, 6)).to eq ''
    end

    it 'should correct return links to pages when last page is active' do
      expect(paging(6, 6)).to eq ''
    end
  end

  describe 'lt' do
    it 'should format date and time' do
      expect(lt(Time.new(2018, 5, 5, 10, 22, 35).utc)).to eq '05.05.2018 08:22:35'
    end

    it 'should return nil if datetime is not provided' do
      expect(lt(nil)).to be nil
    end
  end

  describe 'format_number' do
    it 'should use comma as a delimiter for thousands' do
      expect(format_number(300)).to eq '300'
      expect(format_number(3_000)).to eq '3,000'
      expect(format_number(30_000_000)).to eq '30,000,000'
    end
  end

  describe 'spinner' do
    it 'should return correct content for spinner' do
      expect(spinner).to eq '<div class="spinning"><div class="loader"><svg class="circular" viewBox="25 25 50 50"><circle class="path" cx="50" cy="50" r="20" fill="none" stroke-width="4" stroke-miterlimit="10"/></svg></div></div>'
    end
  end
end
