require 'spec_helper'

describe DashboardsController do
  shared_examples_for :dashboards_controller_xhr_with_access do
    it 'should succeed' do
      expect(response).to be_success
    end

    it 'should initialize dashboard filter' do
      expect(assigns[:filter]).to be_present
      expect(assigns[:filter].partner).to be nil
    end

    it 'should load dashboard data' do
      expect(assigns[:data]).to be_present
    end
  end

  shared_examples_for :dashboards_controller_xhr_with_access_limited_to_partner do
    it 'should succeed' do
      expect(response).to be_success
    end

    it 'should initialize dashboard filter' do
      expect(assigns[:filter]).to be_present
      expect(assigns[:filter].partner).to eq partner_organization.id
    end

    it 'should load dashboard data' do
      expect(assigns[:data]).to be_present
    end
  end

  shared_examples_for :dashboards_controller_xhr_without_access do
    it 'should redirect to login' do
      expect(response).to_not be_success
    end

    it 'should not initialize filter' do
      expect(assigns[:filter]).to be nil
    end

    it 'should not load dashboard data' do
      expect(assigns[:data]).to be nil
    end
  end

  context 'logged in as admin' do
    before do
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

    before { login(:admin) }

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
      before { get :index, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_with_access
    end

    describe 'XHR GET capacity' do
      before { get :capacity, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_with_access
    end

    describe 'XHR GET progress' do
      before { get :progress, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_with_access
    end

    describe 'XHR GET projects' do
      before { get :projects, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_with_access
    end
  end

  context 'logged in as a partner' do
    let(:partner_organization) { Solas::Partner.new id: 3, name: 'Partner Inc.' }

    before do
      login(:partner)
      allow_any_instance_of(Solas::User).to receive(:partner_organization).and_return(partner_organization)

      expect(Solas::Translator).to_not receive(:active_count)
      expect(Solas::Translator).to_not receive(:inactive_count)
      expect(Solas::Translator).to_not receive(:count)

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
        expect(assigns[:filter].partner).to eq partner_organization.id
      end

      it 'should load dashboard data' do
        get :index
        expect(assigns[:data]).to be_present
      end
    end

    describe 'XHR GET index' do
      before { get :index, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_with_access_limited_to_partner
    end

    describe 'XHR GET capacity - no access' do
      before { get :capacity, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_without_access
    end

    describe 'XHR GET progress' do
      before { get :progress, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_with_access_limited_to_partner
    end

    describe 'XHR GET projects' do
      before { get :projects, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_with_access_limited_to_partner
    end
  end

  context 'not logged in' do
    describe 'GET index' do
      before { get :index }

      it 'should redirect to login' do
        expect(response).to redirect_to(login_path)
      end

      it 'should not initialize filter' do
        expect(assigns[:filter]).to be nil
      end

      it 'should not load dashboard data' do
        expect(assigns[:data]).to be nil
      end
    end

    describe 'XHR GET index' do
      before { get :index, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_without_access
    end

    describe 'XHR GET capacity' do
      before { get :capacity, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_without_access
    end

    describe 'XHR GET progress' do
      before { get :progress, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_without_access
    end

    describe 'XHR GET projects' do
      before { get :projects, xhr: true }
      it_should_behave_like :dashboards_controller_xhr_without_access
    end
  end
end
