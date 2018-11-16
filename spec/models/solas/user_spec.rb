require 'spec_helper'

describe Solas::User do
  let(:user) { Solas::User.new id: 5, display_name: 'Alex', email: 'a.nikolskiy@hs-interactive.eu', full_name: 'Alexander Nikolskiy', admin: true }

  describe 'self.from_saml_response' do
    it 'should return a new user with correct attribtues' do
      expect_any_instance_of(Solas::User).to receive(:load_admin_status).and_return true

      response = OpenStruct.new attributes: {
        'urn:oid:0.9.2342.19200300.100.1.1' => '3',
        'urn:oid:2.16.840.1.113730.3.1.241' => 'Alex',
        'urn:oid:1.2.840.113549.1.9.1'      => 'a.nikolskiy@hs-interactive.eu',
        'urn:oid:2.5.4.42'                  => 'Alexander',
        'urn:oid:2.5.4.4'                   => 'Nikolskiy'
      }

      u = Solas::User.from_saml_response(response)

      expect(u.id).to eq 3
      expect(u.display_name).to eq 'Alex'
      expect(u.email).to eq 'a.nikolskiy@hs-interactive.eu'
      expect(u.full_name).to eq 'Alexander Nikolskiy'
      expect(u.admin).to be true
    end
  end

  describe 'self.from_hash' do
    it 'should return a user object created from hash' do
      hash = { 'id' => 5, 'display_name' => 'Alex', 'email' => 'a.nikolskiy@hs-interactive.eu', 'full_name' => 'Alexander Nikolskiy', 'admin' => true }
      u = Solas::User.from_hash(hash)

      expect(u.id).to eq 5
      expect(u.display_name).to eq 'Alex'
      expect(u.email).to eq 'a.nikolskiy@hs-interactive.eu'
      expect(u.full_name).to eq 'Alexander Nikolskiy'
      expect(u.admin).to be true
    end

    it 'should return nil if there is no "id" provided in hash' do
      hash = { 'display_name' => 'Alex', 'email' => 'a.nikolskiy@hs-interactive.eu', 'full_name' => 'Alexander Nikolskiy', 'admin' => true }
      expect(Solas::User.from_hash(hash)).to be nil
    end
  end

  describe 'admin?' do
    it 'should return true if "admin" attribute is set to true' do
      expect(Solas::User.new(admin: true).admin?).to be true
    end

    it 'should return false if "admin" attribute is set to false' do
      expect(Solas::User.new(admin: false).admin?).to be false
    end

    it 'should return false if "admin" attribute is not set' do
      expect(Solas::User.new.admin?).to be false
    end

    it 'should return true if user is a whitelisted superuser' do
      expect(Solas::User.new(id: 777, admin: false).admin?).to be true
    end
  end

  describe 'load_admin_status' do
    it 'should return true if user has a record in Admins table with organisation_id=nil' do
      q = "SELECT COUNT(*) AS count FROM Admins WHERE user_id = #{user.id} AND organisation_id IS NULL"

      expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
        [
          { 'count' => 1 }
        ]
      )

      expect(user.load_admin_status).to be true
    end

    it 'should return true if user does not have a record in Admins table with organisation_id=nil' do
      q = "SELECT COUNT(*) AS count FROM Admins WHERE user_id = #{user.id} AND organisation_id IS NULL"

      expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
        [
          { 'count' => 0 }
        ]
      )

      expect(user.load_admin_status).to be false
    end
  end

  describe 'to_hash' do
    it 'should return a hash with correct user attributes' do
      expect(user.to_hash).to eq(id: 5, display_name: 'Alex', email: 'a.nikolskiy@hs-interactive.eu', full_name: 'Alexander Nikolskiy', admin: true)
    end
  end
end
