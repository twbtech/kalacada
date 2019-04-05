module Solas
  class User < Base
    def self.saml_settings
      idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
      settings            = idp_metadata_parser.parse_remote(SAML_IDP_METADATA_URL)

      settings.issuer = PRODUCTION_SITE_URL
      settings.assertion_consumer_service_url = "#{PRODUCTION_SITE_URL}/saml/consume"

      settings
    end

    def self.from_saml_response(response)
      User.new id:           response.attributes['urn:oid:0.9.2342.19200300.100.1.1'].to_i,
               display_name: response.attributes['urn:oid:2.16.840.1.113730.3.1.241'],
               email:        response.attributes['urn:oid:1.2.840.113549.1.9.1'],
               full_name:    [response.attributes['urn:oid:2.5.4.42'], response.attributes['urn:oid:2.5.4.4']].map(&:presence).compact.join(' ')
    end

    def self.from_hash(hash)
      User.new(hash) if hash.try(:[], 'id').present?
    end

    def self.from_id(id)
      User.new(id: id)
    end

    def initialize(attrs)
      super attrs

      self.role = load_role
    end

    def admin?
      role == :admin || super_user?
    end

    def super_user?
      SUPER_USER_IDS.include?(id)
    end

    def partner?
      !admin? && role == :partner
    end

    def partner_organization
      if partner?
        @partner_organization ||= self.class.query do |connection|
          organization_id = connection.query("SELECT organisation_id FROM Admins WHERE user_id = #{id}").to_a.first['organisation_id']

          Solas::Partner.find(organization_id) if organization_id
        end
      end
    end

    def to_hash
      {
        id:           id,
        display_name: display_name,
        email:        email,
        full_name:    full_name
      }
    end

    private

    def load_role
      self.class.query do |connection|
        if connection.query("SELECT COUNT(*) AS count FROM Admins WHERE user_id = #{id} AND organisation_id IS NULL").to_a.first['count'] > 0
          :admin
        elsif connection.query("SELECT COUNT(*) AS count FROM Admins WHERE user_id = #{id}").to_a.first['count'] > 0
          :partner
        end
      end
    end
  end
end
