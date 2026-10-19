# frozen_string_literal: true

module Docusign
  module Config
    module_function

    def configured?
      [integration_key, user_id, account_id, private_key_pem].all?(&:present?)
    end

    def integration_key
      ENV["DOCUSIGN_INTEGRATION_KEY"].to_s
    end

    def user_id
      ENV["DOCUSIGN_USER_ID"].to_s
    end

    def account_id
      ENV["DOCUSIGN_ACCOUNT_ID"].to_s
    end

    def template_id
      ENV["DOCUSIGN_TEMPLATE_ID"].to_s
    end

    def oauth_host
      ENV.fetch("DOCUSIGN_OAUTH_HOST", "https://account-d.docusign.com")
    end

    def rest_host
      ENV.fetch("DOCUSIGN_REST_HOST", "https://demo.docusign.net")
    end

    def connect_key
      ENV["DOCUSIGN_CONNECT_KEY"].to_s
    end

    def private_key_pem
      ENV["DOCUSIGN_RSA_PRIVATE_KEY"].to_s.gsub('\n', "\n")
    end

    def private_key
      OpenSSL::PKey::RSA.new private_key_pem
    end
  end
end
