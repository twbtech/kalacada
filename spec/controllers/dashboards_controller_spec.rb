require 'spec_helper'

describe DashboardsController do
  before do
    login

    allow(Solas::Translator).to receive(:active_count).and_return(1)
    allow(Solas::Translator).to receive(:inactive_count).and_return(2)
    allow(Solas::Translator).to receive(:count).and_return(3)

    allow(Solas::Word).to receive(:completed_count).and_return(4)
    allow(Solas::Word).to receive(:in_progress_count).and_return(5)
    allow(Solas::Word).to receive(:not_claimed_yet_count).and_return(6)
    allow(Solas::Word).to receive(:overdue_count).and_return(7)

    allow(Solas::Project).to receive(:completed_count).and_return(8)
    allow(Solas::Project).to receive(:in_progress_count).and_return(9)
    allow(Solas::Project).to receive(:not_claimed_yet_count).and_return(10)
    allow(Solas::Project).to receive(:overdue_count).and_return(11)
    allow(Solas::Project).to receive(:count).and_return(38)
    allow(Solas::Project).to receive(:projects).and_return([])

    allow(Solas::Task).to receive(:completed_count).and_return(12)
    allow(Solas::Task).to receive(:in_progress_count).and_return(13)
    allow(Solas::Task).to receive(:not_claimed_yet_count).and_return(14)
    allow(Solas::Task).to receive(:overdue_count).and_return(15)
  end

  describe 'GET index' do
    it 'should succeed' do
      get :index
      expect(response).to be_success
    end

    it 'should initialize filter' do
      get :index
      expect(assigns[:filter]).to be_present
    end

    it 'should load dashboard data' do
      get :index
      expect(assigns[:data]).to be_present
    end
  end

  describe 'XHR GET index' do
    it 'should succeed' do
      get :index, xhr: true
      expect(response).to be_success
    end

    it 'should initialize dashboard filter' do
      get :index, xhr: true
      expect(assigns[:filter]).to be_present
    end

    it 'should load dashboard data' do
      get :index, xhr: true
      expect(assigns[:data]).to be_present
    end
  end

  describe 'XHR GET projects' do
    it 'should succeed' do
      get :projects, xhr: true
      expect(response).to be_success
    end

    it 'should initialize dashboard filter' do
      get :projects, xhr: true
      expect(assigns[:filter]).to be_present
    end

    it 'should load dashboard data' do
      get :projects, xhr: true
      expect(assigns[:data]).to be_present
    end
  end

  describe 'access when logged out' do
    it 'should allow access in development environment' do
      logout
      allow(Rails.env).to receive(:development?).and_return true

      get :index
      expect(response).to be_success
    end

    it 'should redirect to login in production environment' do
      logout
      allow(Rails.env).to receive(:development?).and_return false
      allow(Rails.env).to receive(:production?).and_return true

      get :index
      expect(response).to redirect_to(login_path)
    end
  end
end
