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
      User.new.tap do |user|
        user.id           = response.attributes['urn:oid:0.9.2342.19200300.100.1.1'].to_i
        user.display_name = response.attributes['urn:oid:2.16.840.1.113730.3.1.241']
        user.email        = response.attributes['urn:oid:1.2.840.113549.1.9.1']
        user.full_name    = [response.attributes['urn:oid:2.5.4.42'], response.attributes['urn:oid:2.5.4.4']].map(&:presence).compact.join(' ')
        user.admin        = user.load_admin_status
      end
    end

    def self.from_hash(hash)
      User.new(hash) if hash.try(:[], 'id').present?
    end

    def admin?
      admin.present? || SUPER_USER_IDS.include?(id)
    end

    def load_admin_status
      self.class.query do |connection|
        connection.query("SELECT COUNT(*) AS count FROM Admins WHERE user_id = #{id} AND organisation_id IS NULL").to_a.first['count'] > 0
      end
    end

    def to_hash
      {
        id:           id,
        display_name: display_name,
        email:        email,
        full_name:    full_name,
        admin:        admin
      }
    end
  end
end
