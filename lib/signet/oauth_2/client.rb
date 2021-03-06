# Copyright (C) 2010 Google Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

gem 'faraday', '~> 0.8.1'
require 'faraday'

require 'stringio'
require 'addressable/uri'
require 'signet'
require 'signet/errors'
require 'signet/oauth_2'

gem 'jwt', '~> 0.1.4'
require 'jwt'

module Signet
  module OAuth2
    class Client
      ##
      # Creates an OAuth 2.0 client.
      #
      # @param [Hash] options
      #   The configuration parameters for the client.
      #   - <code>:authorization_uri</code> —
      #     The authorization server's HTTP endpoint capable of
      #     authenticating the end-user and obtaining authorization.
      #   - <code>:token_credential_uri</code> —
      #     The authorization server's HTTP endpoint capable of issuing
      #     tokens and refreshing expired tokens.
      #   - <code>:client_id</code> —
      #     A unique identifier issued to the client to identify itself to the
      #     authorization server.
      #   - <code>:client_secret</code> —
      #     A shared symmetric secret issued by the authorization server,
      #     which is used to authenticate the client.
      #   - <code>:scope</code> —
      #     The scope of the access request, expressed either as an Array
      #     or as a space-delimited String.
      #   - <code>:state</code> —
      #     An arbitrary string designed to allow the client to maintain state.
      #   - <code>:code</code> —
      #     The authorization code received from the authorization server.
      #   - <code>:redirect_uri</code> —
      #     The redirection URI used in the initial request.
      #   - <code>:username</code> —
      #     The resource owner's username.
      #   - <code>:password</code> —
      #     The resource owner's password.
      #   - <code>:refresh_token</code> —
      #     The refresh token associated with the access token
      #     to be refreshed.
      #   - <code>:access_token</code> —
      #     The current access token for this client.
      #   - <code>:id_token</code> —
      #     The current ID token for this client.
      #   - <code>:extension_parameters</code> —
      #     When using an extension grant type, this the set of parameters used
      #     by that extension.
      #
      # @example
      #   client = Signet::OAuth2::Client.new(
      #     :authorization_endpoint_uri =>
      #       'https://example.server.com/authorization',
      #     :token_endpoint_uri =>
      #       'https://example.server.com/token',
      #     :client_id => 'anonymous',
      #     :client_secret => 'anonymous',
      #     :scope => 'example',
      #     :redirect_uri => 'https://example.client.com/oauth'
      #   )
      #
      # @see Signet::OAuth2::Client#update!
      def initialize(options={})
        self.update!(options)
      end

      ##
      # Updates an OAuth 2.0 client.
      #
      # @param [Hash] options
      #   The configuration parameters for the client.
      #   - <code>:authorization_uri</code> —
      #     The authorization server's HTTP endpoint capable of
      #     authenticating the end-user and obtaining authorization.
      #   - <code>:token_credential_uri</code> —
      #     The authorization server's HTTP endpoint capable of issuing
      #     tokens and refreshing expired tokens.
      #   - <code>:client_id</code> —
      #     A unique identifier issued to the client to identify itself to the
      #     authorization server.
      #   - <code>:client_secret</code> —
      #     A shared symmetric secret issued by the authorization server,
      #     which is used to authenticate the client.
      #   - <code>:scope</code> —
      #     The scope of the access request, expressed either as an Array
      #     or as a space-delimited String.
      #   - <code>:state</code> —
      #     An arbitrary string designed to allow the client to maintain state.
      #   - <code>:code</code> —
      #     The authorization code received from the authorization server.
      #   - <code>:redirect_uri</code> —
      #     The redirection URI used in the initial request.
      #   - <code>:username</code> —
      #     The resource owner's username.
      #   - <code>:password</code> —
      #     The resource owner's password.
      #   - <code>:refresh_token</code> —
      #     The refresh token associated with the access token
      #     to be refreshed.
      #   - <code>:access_token</code> —
      #     The current access token for this client.
      #   - <code>:id_token</code> —
      #     The current ID token for this client.
      #   - <code>:extension_parameters</code> —
      #     When using an extension grant type, this the set of parameters used
      #     by that extension.
      #
      # @example
      #   client.update!(
      #     :code => 'i1WsRn1uB1',
      #     :access_token => 'FJQbwq9',
      #     :expires_in => 3600
      #   )
      #
      # @see Signet::OAuth2::Client#initialize
      # @see Signet::OAuth2::Client#update_token!
      def update!(options={})
        # Normalize key to String to allow indifferent access.
        options = options.inject({}) { |accu, (k, v)| accu[k.to_s] = v; accu }
        self.authorization_uri = options["authorization_uri"]
        self.token_credential_uri = options["token_credential_uri"]
        self.client_id = options["client_id"]
        self.client_secret = options["client_secret"]
        self.scope = options["scope"]
        self.state = options["state"]
        self.code = options["code"]
        self.redirect_uri = options["redirect_uri"]
        self.username = options["username"]
        self.password = options["password"]
        self.extension_parameters = options["extension_parameters"] || {}
        self.update_token!(options)
        return self
      end

      ##
      # Updates an OAuth 2.0 client.
      #
      # @param [Hash] options
      #   The configuration parameters related to the token.
      #   - <code>:refresh_token</code> —
      #     The refresh token associated with the access token
      #     to be refreshed.
      #   - <code>:access_token</code> —
      #     The current access token for this client.
      #   - <code>:id_token</code> —
      #     The current ID token for this client.
      #   - <code>:expires_in</code> —
      #     The time in seconds until access token expiration.
      #   - <code>:issued_at</code> —
      #     The timestamp that the token was issued at.
      #
      # @example
      #   client.update!(
      #     :refresh_token => 'n4E9O119d',
      #     :access_token => 'FJQbwq9',
      #     :expires_in => 3600
      #   )
      #
      # @see Signet::OAuth2::Client#initialize
      # @see Signet::OAuth2::Client#update!
      def update_token!(options={})
        # Normalize key to String to allow indifferent access.
        options = options.inject({}) { |accu, (k, v)| accu[k.to_s] = v; accu }

        self.access_token = options["access_token"] if options["access_token"]
        self.expires_in = options["expires_in"] if options["expires_in"]

        # The refresh token may not be returned in a token response.
        # In which case, the old one should continue to be used.
        if options["refresh_token"]
          self.refresh_token = options["refresh_token"]
        end
        # The ID token may not be returned in a token response.
        # In which case, the old one should continue to be used.
        if options["id_token"]
          self.id_token = options["id_token"]
        end
        # By default, the token is issued at `Time.now` when `expires_in` is
        # set, but this can be used to supply a more precise time.
        if options["issued_at"]
          self.issued_at = options["issued_at"]
        end

        return self
      end

      ##
      # Returns the authorization URI that the user should be redirected to.
      #
      # @return [Addressable::URI] The authorization URI.
      #
      # @see Signet::OAuth2.generate_authorization_uri
      def authorization_uri(options={})
        return nil if @authorization_uri == nil
        unless options[:response_type]
          options[:response_type] = :code
        end
        unless options[:access_type]
          options[:access_type] = :offline
        end
        unless options[:approval_prompt]
          # This default will likely change in the future.
          options[:approval_prompt] = :force
        end
        options[:client_id] ||= self.client_id
        options[:redirect_uri] ||= self.redirect_uri
        if !options[:client_id]
          raise ArgumentError, "Missing required client identifier."
        end
        unless options[:redirect_uri]
          raise ArgumentError, "Missing required redirect URI."
        end
        if !options[:scope] && self.scope
          options[:scope] = self.scope.join(' ')
        end
        options[:state] = self.state unless options[:state]
        uri = Addressable::URI.parse(
          ::Signet::OAuth2.generate_authorization_uri(
            @authorization_uri, options
          )
        )
        if uri.normalized_scheme != 'https'
          raise Signet::UnsafeOperationError,
            'Authorization endpoint must be protected by TLS.'
        end
        return uri
      end

      ##
      # Sets the authorization URI for this client.
      #
      # @param [Addressable::URI, String, #to_str] new_authorization_uri
      #   The authorization URI.
      def authorization_uri=(new_authorization_uri)
        if new_authorization_uri != nil
          new_authorization_uri =
            Addressable::URI.parse(new_authorization_uri)
          @authorization_uri = new_authorization_uri
        else
          @authorization_uri = nil
        end
      end

      ##
      # Returns the token credential URI for this client.
      #
      # @return [Addressable::URI] The token credential URI.
      def token_credential_uri
        return @token_credential_uri
      end

      ##
      # Sets the token credential URI for this client.
      #
      # @param [Addressable::URI, String, #to_str] new_token_credential_uri
      #   The token credential URI.
      def token_credential_uri=(new_token_credential_uri)
        if new_token_credential_uri != nil
          new_token_credential_uri =
            Addressable::URI.parse(new_token_credential_uri)
          @token_credential_uri = new_token_credential_uri
        else
          @token_credential_uri = nil
        end
      end

      ##
      # Returns the client identifier for this client.
      #
      # @return [String] The client identifier.
      def client_id
        return @client_id
      end

      ##
      # Sets the client identifier for this client.
      #
      # @param [String] new_client_id
      #   The client identifier.
      def client_id=(new_client_id)
        @client_id = new_client_id
      end

      ##
      # Returns the client secret for this client.
      #
      # @return [String] The client secret.
      def client_secret
        return @client_secret
      end

      ##
      # Sets the client secret for this client.
      #
      # @param [String] new_client_secret
      #   The client secret.
      def client_secret=(new_client_secret)
        @client_secret = new_client_secret
      end

      ##
      # Returns the scope for this client.  Scope is a list of access ranges
      # defined by the authorization server.
      #
      # @return [Array] The scope of access the client is requesting.
      def scope
        return @scope
      end

      ##
      # Sets the scope for this client.
      #
      # @param [Array, String] new_scope
      #   The scope of access the client is requesting.  This may be
      #   expressed as either an Array of String objects or as a
      #   space-delimited String.
      def scope=(new_scope)
        case new_scope
        when Array
          new_scope.each do |scope|
            if scope.include?(' ')
              raise ArgumentError,
                "Individual scopes cannot contain the space character."
            end
          end
          @scope = new_scope
        when String
          @scope = new_scope.split(' ')
        when nil
          @scope = nil
        else
          raise TypeError, "Expected Array or String, got #{new_scope.class}"
        end
      end

      ##
      # Returns the client's current state value.
      #
      # @return [String] The state value.
      def state
        return @state
      end

      ##
      # Sets the client's current state value.
      #
      # @param [String] new_state
      #   The state value.
      def state=(new_state)
        @state = new_state
      end

      ##
      # Returns the authorization code issued to this client.
      # Used only by the authorization code access grant type.
      #
      # @return [String] The authorization code.
      def code
        return @code
      end

      ##
      # Sets the authorization code issued to this client.
      # Used only by the authorization code access grant type.
      #
      # @param [String] new_code
      #   The authorization code.
      def code=(new_code)
        @code = new_code
      end

      ##
      # Returns the redirect URI for this client.
      #
      # @return [String] The redirect URI.
      def redirect_uri
        return @redirect_uri
      end

      ##
      # Sets the redirect URI for this client.
      #
      # @param [String] new_redirect_uri
      #   The redirect URI.
      def redirect_uri=(new_redirect_uri)
        new_redirect_uri = Addressable::URI.parse(new_redirect_uri)
        if new_redirect_uri == nil || new_redirect_uri.absolute?
          @redirect_uri = new_redirect_uri
        else
          raise ArgumentError, "Redirect URI must be an absolute URI."
        end
      end

      ##
      # Returns the username associated with this client.
      # Used only by the resource owner password credential access grant type.
      #
      # @return [String] The username.
      def username
        return @username
      end

      ##
      # Sets the username associated with this client.
      # Used only by the resource owner password credential access grant type.
      #
      # @param [String] new_username
      #   The username.
      def username=(new_username)
        @username = new_username
      end

      ##
      # Returns the password associated with this client.
      # Used only by the resource owner password credential access grant type.
      #
      # @return [String] The password.
      def password
        return @password
      end

      ##
      # Sets the password associated with this client.
      # Used only by the resource owner password credential access grant type.
      #
      # @param [String] new_password
      #   The password.
      def password=(new_password)
        @password = new_password
      end

      ##
      # Returns the set of extension parameters used by the client.
      # Used only by extension access grant types.
      #
      # @return [Hash] The extension parameters.
      def extension_parameters
        return @extension_parameters ||= {}
      end

      ##
      # Sets extension parameters used by the client.
      # Used only by extension access grant types.
      #
      # @param [Hash] new_extension_parameters
      #   The parameters.
      def extension_parameters=(new_extension_parameters)
        if new_extension_parameters.respond_to?(:to_hash)
          @extension_parameters = new_extension_parameters.to_hash
        else
          raise TypeError,
            "Expected Hash, got #{new_extension_parameters.class}."
        end
      end

      ##
      # Returns the refresh token associated with this client.
      #
      # @return [String] The refresh token.
      def refresh_token
        return @refresh_token ||= nil
      end

      ##
      # Sets the refresh token associated with this client.
      #
      # @param [String] new_refresh_token
      #   The refresh token.
      def refresh_token=(new_refresh_token)
        @refresh_token = new_refresh_token
      end

      ##
      # Returns the access token associated with this client.
      #
      # @return [String] The access token.
      def access_token
        return @access_token ||= nil
      end

      ##
      # Sets the access token associated with this client.
      #
      # @param [String] new_access_token
      #   The access token.
      def access_token=(new_access_token)
        @access_token = new_access_token
      end

      ##
      # Returns the ID token associated with this client.
      #
      # @return [String] The ID token.
      def id_token
        return @id_token ||= nil
      end

      ##
      # Sets the ID token associated with this client.
      #
      # @param [String] new_id_token
      #   The ID token.
      def id_token=(new_id_token)
        @id_token = new_id_token
      end

      ##
      # Returns the decoded ID token associated with this client.
      #
      # @param [OpenSSL::PKey::RSA, Object] public_key
      #   The public key to use to verify the ID token. Skips verification if
      #   omitted.
      #
      # @return [String] The decoded ID token.
      def decoded_id_token(public_key=nil)
        decoded = JWT.decode(self.id_token, public_key, !!public_key)
        if !decoded.has_key?('aud')
          raise Signet::UnsafeOperationError, 'No ID token audience declared.'
        elsif decoded['aud'] != self.client_id
          raise Signet::UnsafeOperationError,
            'ID token audience did not match Client ID.'
        end
        return decoded
      end

      ##
      # Returns the lifetime of the access token in seconds.
      #
      # @return [Integer] The access token lifetime.
      def expires_in
        return @expires_in
      end

      ##
      # Sets the lifetime of the access token in seconds.  Resets the issued
      # timestamp.
      #
      # @param [String] new_expires_in
      #   The access token lifetime.
      def expires_in=(new_expires_in)
        if new_expires_in != nil
          @expires_in = new_expires_in.to_i
          @issued_at = Time.now
        else
          @expires_in, @issued_at = nil, nil
        end
      end

      ##
      # Returns the timestamp the access token was issued at.
      #
      # @return [Integer] The access token issuance time.
      def issued_at
        return @issued_at
      end

      ##
      # Sets the timestamp the access token was issued at.
      #
      # @param [String] new_issued_at
      #    The access token issuance time.
      def issued_at=(new_issued_at)
        @issued_at = new_issued_at
      end

      ##
      # Returns the timestamp the access token will expire at.
      #
      # @return [Integer] The access token lifetime.
      def expires_at
        if @issued_at && @expires_in
          return @issued_at + @expires_in
        else
          return nil
        end
      end

      ##
      # Returns true if the access token has expired.
      #
      # @return [TrueClass, FalseClass]
      #   The expiration state of the access token.
      def expired?
        return self.expires_at != nil && Time.now >= self.expires_at
      end

      ##
      # Returns the inferred grant type, based on the current state of the
      # client object.  Returns `"none"` if the client has insufficient
      # information to make an in-band authorization request.
      #
      # @return [String]
      #   The inferred grant type.
      def grant_type
        @grant_type ||= nil
        if @grant_type
          return @grant_type
        else
          if self.code && self.redirect_uri
            'authorization_code'
          elsif self.refresh_token
            'refresh_token'
          elsif self.username && self.password
            'password'
          else
            # We don't have sufficient auth information, assume an out-of-band
            # authorization arrangement between the client and server, or an
            # extension grant type.
            nil
          end
        end
      end

      def grant_type=(new_grant_type)
        case new_grant_type
        when 'authorization_code', 'refresh_token',
            'password', 'client_credentials'
          @grant_type = new_grant_type
        else
          @grant_type = Addressable::URI.parse(new_grant_type)
        end
      end

      ##
      # Generates a request for token credentials.
      #
      # @param [Hash] options
      #   The configuration parameters for the request.
      #   - <code>:code</code> —
      #     The authorization code.
      #
      # @return [Array] The request object.
      def generate_access_token_request(options={})
        if self.token_credential_uri == nil
          raise ArgumentError, 'Missing token endpoint URI.'
        end

        options[:connection] ||= Faraday.default_connection
        method = 'POST'
        parameters = {"grant_type" => self.grant_type}
        case self.grant_type
        when 'authorization_code'
          parameters['code'] = self.code
          parameters['redirect_uri'] = self.redirect_uri
        when 'password'
          parameters['username'] = self.username
          parameters['password'] = self.password
        when 'refresh_token'
          parameters['refresh_token'] = self.refresh_token
        else
          if self.redirect_uri
            # Grant type was intended to be `authorization_code` because of
            # the presence of the redirect URI.
            raise ArgumentError, 'Missing authorization code.'
          end
          parameters.merge!(self.extension_parameters)
        end
        parameters['client_id'] = self.client_id unless self.client_id.nil?
        parameters['client_secret'] = self.client_secret unless self.client_secret.nil?
        headers = [
          ['Cache-Control', 'no-store'],
          ['Content-Type', 'application/x-www-form-urlencoded']
        ]
        return options[:connection].build_request(
          method.to_s.downcase.to_sym
        ) do |req|
          req.url(Addressable::URI.parse(
            self.token_credential_uri
          ).normalize.to_s)
          req.headers = Faraday::Utils::Headers.new(headers)
          req.body = Addressable::URI.form_encode(parameters)
        end
      end

      def fetch_access_token(options={})
        options[:connection] ||= Faraday.default_connection
        request = self.generate_access_token_request(options)
        request_env = request.to_env(options[:connection])
        request_env[:request] ||= request
        response = options[:connection].app.call(request_env)
        if response.status.to_i == 200
          return ::Signet::OAuth2.parse_json_credentials(response.body)
        elsif [400, 401, 403].include?(response.status.to_i)
          message = 'Authorization failed.'
          if response.body.to_s.strip.length > 0
            message += "  Server message:\n#{response.body.to_s.strip}"
          end
          raise ::Signet::AuthorizationError.new(
            message, :request => request, :response => response
          )
        else
          message = "Unexpected status code: #{response.status}."
          if response.body.to_s.strip.length > 0
            message += "  Server message:\n#{response.body.to_s.strip}"
          end
          raise ::Signet::AuthorizationError.new(
            message, :request => request, :response => response
          )
        end
      end

      def fetch_access_token!(options={})
        token_hash = self.fetch_access_token(options)
        if token_hash
          # No-op for grant types other than `authorization_code`.
          # An authorization code is a one-time use token and is immediately
          # revoked after usage.
          self.code = nil
          self.issued_at = Time.now
          self.update_token!(token_hash)
        end
        return token_hash
      end

      ##
      # Generates an authenticated request for protected resources.
      #
      # @param [Hash] options
      #   The configuration parameters for the request.
      #   - <code>:request</code> —
      #     A pre-constructed request.  An OAuth 2 Authorization header
      #     will be added to it, as well as an explicit Cache-Control
      #     `no-store` directive.
      #   - <code>:method</code> —
      #     The HTTP method for the request.  Defaults to 'GET'.
      #   - <code>:uri</code> —
      #     The URI for the request.
      #   - <code>:headers</code> —
      #     The HTTP headers for the request.
      #   - <code>:body</code> —
      #     The HTTP body for the request.
      #   - <code>:realm</code> —
      #     The Authorization realm.  See RFC 2617.
      #
      # @return [Faraday::Request] The request object.
      def generate_authenticated_request(options={})
        if self.access_token == nil
          raise ArgumentError, 'Missing access token.'
        end
        options = {
          :realm => nil
        }.merge(options)

        if options[:request].kind_of?(Faraday::Request)
          request = options[:request]
        else
          if options[:request].kind_of?(Array)
            method, uri, headers, body = options[:request]
          else
            method = options[:method] || :get
            uri = options[:uri]
            headers = options[:headers] || []
            body = options[:body] || ''
          end
          headers = headers.to_a if headers.kind_of?(Hash)
          request_components = {
            :method => method,
            :uri => uri,
            :headers => headers,
            :body => body
          }
          # Verify that we have all pieces required to return an HTTP request
          request_components.each do |(key, value)|
            unless value
              raise ArgumentError, "Missing :#{key} parameter."
            end
          end
          method = method.to_s.downcase.to_sym
          request = options[:connection].build_request(method.to_s.downcase.to_sym) do |req|
            req.url(Addressable::URI.parse(uri).normalize.to_s)
            req.headers = Faraday::Utils::Headers.new(headers)
            req.body = body
          end
        end
        
        request['Authorization'] = ::Signet::OAuth2.generate_bearer_authorization_header(
          self.access_token,
          options[:realm] ? [['realm', options[:realm]]] : nil
        )
        request['Cache-Control'] = 'no-store'
        return request
      end

      ##
      # Transmits a request for a protected resource.
      #
      # @param [Hash] options
      #   The configuration parameters for the request.
      #   - <code>:request</code> —
      #     A pre-constructed request.  An OAuth 2 Authorization header
      #     will be added to it, as well as an explicit Cache-Control
      #     `no-store` directive.
      #   - <code>:method</code> —
      #     The HTTP method for the request.  Defaults to 'GET'.
      #   - <code>:uri</code> —
      #     The URI for the request.
      #   - <code>:headers</code> —
      #     The HTTP headers for the request.
      #   - <code>:body</code> —
      #     The HTTP body for the request.
      #   - <code>:realm</code> —
      #     The Authorization realm.  See RFC 2617.
      #   - <code>:connection</code> —
      #     The HTTP connection to use.
      #     Must be of type <code>Faraday::Connection</code>.
      #
      # @example
      #   # Using Net::HTTP
      #   response = client.fetch_protected_resource(
      #     :uri => 'http://www.example.com/protected/resource'
      #   )
      #
      # @example
      #   # Using Typhoeus
      #   response = client.fetch_protected_resource(
      #     :request => Typhoeus::Request.new(
      #       'http://www.example.com/protected/resource'
      #     ),
      #     :adapter => HTTPAdapter::TyphoeusAdapter.new,
      #     :connection => connection
      #   )
      #
      # @return [Array] The response object.
      def fetch_protected_resource(options={})
        options[:connection] ||= Faraday.default_connection
        request = self.generate_authenticated_request(options)
        request_env = request.to_env(options[:connection])
        request_env[:request] ||= request
        response = options[:connection].app.call(request_env)
        if response.status.to_i == 401
          # When accessing a protected resource, we only want to raise an
          # error for 401 responses.
          message = 'Authorization failed.'
          if response.body.to_s.strip.length > 0
            message += "  Server message:\n#{response.body.to_s.strip}"
          end
          raise ::Signet::AuthorizationError.new(
            message, :request => request, :response => response
          )
        else
          return response
        end
      end
    end
  end
end
