require 'spec_helper'

describe SessionsController do
  describe 'GET login' do
    it 'should succeed' do
      get :login
      expect(response).to be_success
    end
  end

  describe 'GET logout' do
    it 'should reset session' do
      expect_any_instance_of(ApplicationController).to receive(:reset_session)
      get :logout
    end

    it 'should redirect to login page' do
      get :logout
      expect(response).to redirect_to(login_path)
    end
  end
end
