require 'spec_helper'

describe Solas::User do
  let(:user) { Solas::User.new id: 5, display_name: 'Alex', email: 'a.nikolskiy@hs-interactive.eu', full_name: 'Alexander Nikolskiy' }

  describe 'self.from_saml_response' do
    it 'should return a new user with correct attribtues' do
      expect_any_instance_of(Solas::User).to receive(:load_role).and_return :admin

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
      expect(u.admin?).to be true
    end
  end

  describe 'self.from_hash' do
    it 'should return a user object created from hash' do
      expect_any_instance_of(Solas::User).to receive(:load_role).and_return :admin

      hash = { 'id' => 5, 'display_name' => 'Alex', 'email' => 'a.nikolskiy@hs-interactive.eu', 'full_name' => 'Alexander Nikolskiy' }
      u = Solas::User.from_hash(hash)

      expect(u.id).to eq 5
      expect(u.display_name).to eq 'Alex'
      expect(u.email).to eq 'a.nikolskiy@hs-interactive.eu'
      expect(u.full_name).to eq 'Alexander Nikolskiy'
      expect(u.admin?).to be true
    end

    it 'should return nil if there is no "id" provided in hash' do
      hash = { 'display_name' => 'Alex', 'email' => 'a.nikolskiy@hs-interactive.eu', 'full_name' => 'Alexander Nikolskiy' }
      expect(Solas::User.from_hash(hash)).to be nil
    end
  end

  describe 'admin?' do
    context 'role is admin' do
      it 'should return true' do
        expect_any_instance_of(Solas::User).to receive(:load_role).and_return :admin
        expect(Solas::User.new({}).admin?).to be true
      end
    end

    context 'role is partner' do
      before { expect_any_instance_of(Solas::User).to receive(:load_role).and_return :partner }

      it 'should return false' do
        expect(Solas::User.new({}).admin?).to be false
      end

      it 'should return true if user is a whitelisted superuser' do
        expect(Solas::User.new(id: 777).admin?).to be true
      end
    end

    context 'role is not set' do
      before { expect_any_instance_of(Solas::User).to receive(:load_role).and_return nil }

      it 'should return false' do
        expect(Solas::User.new({}).admin?).to be false
      end

      it 'should return true if user is a whitelisted superuser' do
        expect(Solas::User.new(id: 777).admin?).to be true
      end
    end
  end

  describe 'partner?' do
    context 'role is admin' do
      it 'should return false' do
        expect_any_instance_of(Solas::User).to receive(:load_role).and_return :admin
        expect(Solas::User.new({}).partner?).to be false
      end
    end

    context 'role is partner' do
      before { expect_any_instance_of(Solas::User).to receive(:load_role).and_return :partner }

      it 'should return true' do
        expect(Solas::User.new({}).partner?).to be true
      end

      it 'should return true if user is a whitelisted superuser' do
        expect(Solas::User.new(id: 777).partner?).to be false
      end
    end

    context 'role is not set' do
      before { expect_any_instance_of(Solas::User).to receive(:load_role).and_return nil }

      it 'should return false' do
        expect(Solas::User.new({}).partner?).to be false
      end

      it 'should return true if user is a whitelisted superuser' do
        expect(Solas::User.new(id: 777).partner?).to be false
      end
    end
  end

  describe 'partner_organization' do
    context 'user is an admin' do
      before { expect_any_instance_of(Solas::User).to receive(:load_role).and_return :admin }

      it 'should return nil' do
        expect(user.partner_organization).to be nil
      end
    end

    context 'user is a partner' do
      before { expect_any_instance_of(Solas::User).to receive(:load_role).and_return :partner }

      it 'should find and return partner organization' do
        q = 'SELECT organisation_id FROM Admins WHERE user_id = 5'

        expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
          [
            { 'organisation_id' => 3 }
          ]
        )

        q = 'SELECT partners_kp.* FROM partners_kp WHERE partners_kp.kpid = 3'

        expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
          [
            { 'kpid' => 3, 'name' => 'Partner Inc.' }
          ]
        )

        expect(user.partner_organization).to eq Solas::Partner.new(id: 3, name: 'Partner Inc.')
      end
    end

    context 'user has no role' do
      before { expect_any_instance_of(Solas::User).to receive(:load_role).and_return nil }

      it 'should return nil' do
        expect(user.partner_organization).to be nil
      end
    end
  end

  describe 'load_role' do
    it 'should set user role to "admin" if user has a record in Admins table with organisation_id=nil' do
      q = 'SELECT COUNT(*) AS count FROM Admins WHERE user_id = 5 AND organisation_id IS NULL'

      expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
        [
          { 'count' => 1 }
        ]
      )

      expect(user.role).to be :admin
    end

    it 'should set user role to "partner" if user has a record in Admins table, but he is not "admin"' do
      q = 'SELECT COUNT(*) AS count FROM Admins WHERE user_id = 5 AND organisation_id IS NULL'

      expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
        [
          { 'count' => 0 }
        ]
      )

      q = 'SELECT COUNT(*) AS count FROM Admins WHERE user_id = 5'

      expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
        [
          { 'count' => 1 }
        ]
      )

      expect(user.role).to be :partner
    end

    it 'should not set user role if user does not have a record in Admins table' do
      q = 'SELECT COUNT(*) AS count FROM Admins WHERE user_id = 5 AND organisation_id IS NULL'

      expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
        [
          { 'count' => 0 }
        ]
      )

      q = 'SELECT COUNT(*) AS count FROM Admins WHERE user_id = 5'

      expect_any_instance_of(Solas::Connection).to receive(:query).with(q).and_return(
        [
          { 'count' => 0 }
        ]
      )

      expect(user.role).to be nil
    end
  end

  describe 'to_hash' do
    it 'should return a hash with correct user attributes' do
      expect_any_instance_of(Solas::User).to receive(:load_role).and_return :admin
      expect(user.to_hash).to eq(id: 5, display_name: 'Alex', email: 'a.nikolskiy@hs-interactive.eu', full_name: 'Alexander Nikolskiy')
    end
  end
end
