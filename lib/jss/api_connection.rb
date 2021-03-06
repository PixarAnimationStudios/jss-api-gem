### Copyright 2020 Pixar
###
###    Licensed under the Apache License, Version 2.0 (the "Apache License")
###    with the following modification; you may not use this file except in
###    compliance with the Apache License and the following modification to it:
###    Section 6. Trademarks. is deleted and replaced with:
###
###    6. Trademarks. This License does not grant permission to use the trade
###       names, trademarks, service marks, or product names of the Licensor
###       and its affiliates, except as required to comply with Section 4(c) of
###       the License and to reproduce the content of the NOTICE file.
###
###    You may obtain a copy of the Apache License at
###
###        http://www.apache.org/licenses/LICENSE-2.0
###
###    Unless required by applicable law or agreed to in writing, software
###    distributed under the Apache License with the above modification is
###    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
###    KIND, either express or implied. See the Apache License for the specific
###    language governing permissions and limitations under the Apache License.
###
###

###
module JSS

  # Instances of this class represent a REST connection to a JSS API.
  #
  # For most cases, a single connection to a single JSS is all you need, and
  # this is ruby-jss's default behavior.
  #
  # If needed, multiple connections can be made and used sequentially or
  # simultaneously.
  #
  # == Using the default connection
  #
  # When ruby-jss is loaded, a not-yet-connected default instance of
  # JSS::APIConnection is created and stored in the constant JSS::API.
  # This connection is used as the initial 'active connection' (see below)
  # so all methods that make API calls will use it by default. For most uses,
  # where you're only going to be working with one connection to one JSS, the
  # default connection is all you need.
  #
  # Before using it you must call its {#connect} method, passing in appropriate
  # connection details and credentials.
  #
  # Example:
  #
  #    require 'ruby-jss'
  #    JSS.api.connect server: 'server.address.edu', user: 'jss-api-user', pw: :prompt
  #    # (see {JSS::APIConnection#connect} for all the connection options)
  #
  #    a_phone = JSS::MobileDevice.fetch id: 8743
  #
  #    # the mobile device was fetched through the default connection
  #
  # == Using Multiple Simultaneous Connections
  #
  # Sometimes you need to connect simultaneously to more than one JSS.
  # or to the same JSS with different credentials. ruby-jss allows you to
  # create as many connections as needed, and gives you three ways to use them:
  #
  # 1. Making a connection 'active', after which API calls go thru it
  #    automatically
  #
  #    Example:
  #
  #        a_computer = JSS::Computer.fetch id: 1234
  #
  #        # the JSS::Computer with id 1234 is fetched from the active connection
  #        # and stored in the variable 'a_computer'
  #
  #    NOTE: When ruby-jss is first loaded, the default connection (see above)
  #    is the active connection.
  #
  # 2. Passing an APIConnection instance to methods that use the API
  #
  #    Example:
  #
  #         a_computer = JSS::Computer.fetch id: 1234, api: production_api
  #
  #         # the JSS::Computer with id 1234 is fetched from the connection
  #         # stored in the variable 'production_api'. The computer is
  #         # then stored in the variable 'a_computer'
  #
  # 3. Using the APIConnection instance itself to make API calls.
  #
  #    Example:
  #
  #         a_computer = production_api.fetch :Computer, id: 1234
  #
  #         # the JSS::Computer with id 1234 is fetched from the connection
  #         # stored in the variable 'production_api'. The computer is
  #         # then stored in the variable 'a_computer'
  #
  # See below for more details about the ways to use multiple connections.
  #
  # NOTE:
  # Objects retrieved or created through an APIConnection store an internal
  # reference to that APIConnection and use that when they make other API
  # calls, thus ensuring data consistency when using multiple connections.
  #
  # Similiarly, the data caches used by APIObject list methods (e.g.
  # JSS::Computer.all, .all_names, and so on) are stored in the APIConnection
  # instance through which they were read, so they won't be incorrect when
  # you use multiple connections.
  #
  # == Making new APIConnection instances
  #
  # New connections can be created using the standard ruby 'new' method.
  #
  # If you provide connection details when calling 'new', they will be passed
  # to the {#connect} method immediately. Otherwise you can call {#connect} later.
  #
  #   production_api = JSS::APIConnection.new(
  #     name: 'prod',
  #     server: 'prodserver.address.org',
  #     user: 'produser',
  #     pw: :prompt
  #   )
  #
  #   # the new connection is now stored in the variable 'production_api'.
  #
  # == Using the 'Active' Connection
  #
  # While multiple connection instances can be created, only one at a time is
  # 'the active connection' and all APIObject-based access methods in ruby-jss
  # will use it automatically. When ruby-jss is loaded, the  default connection
  # (see above) is the active connection.
  #
  # To use the active connection, just call a method on an APIObject subclass
  # that uses the API.
  #
  # For example, the various list methods:
  #
  #   all_computer_sns = JSS::Computer.all_serial_numbers
  #
  #   # the list of all computer serial numbers is read from the active
  #   # connection and stored in all_computer_sns
  #
  # Fetching an object from the API:
  #
  #   victim_md = JSS::MobileDevice.fetch id: 832
  #
  #   # the variable 'victim_md' now contains a JSS::MobileDevice queried
  #   # through the active connection.
  #
  # The currently-active connection instance is available from the
  # `JSS.api` method.
  #
  # === Making a Connection Active
  #
  # Only one connection is 'active' at a time and the currently active one is
  # returned when you call `JSS.api` or its alias `JSS.active_connection`
  #
  # To activate another connection just pass it to the JSS.use_api method like so:
  #
  #   JSS.use_api production_api
  #   # the connection we stored in 'production_api' is now active
  #
  # To re-activate to the default connection, just call
  #   JSS.use_default_connection
  #
  # == Connection Names:
  #
  # As seen in the example above, you can provide a 'name:' parameter
  # (a String or a Symbol) when creating a new connection. The name can be
  # used later to identify connection objects.
  #
  # If you don't provide one, the name is ':disconnected' until you
  # connect, and then 'user@server:port' after connecting.
  #
  # The name of the default connection is always :default
  #
  # To see the name of the currently active connection, just use `JSS.api.name`
  #
  #   JSS.use_api production_api
  #   JSS.api.name  # => 'prod'
  #
  #   JSS.use_default_connection
  #   JSS.api.name  # => :default
  #
  # == Creating, Storing and Activating a connection in one step
  #
  # Both of the above steps (creating/storing a connection, and making it
  # active) can be performed in one step using the
  # `JSS.new_api_connection` method, which creates a new APIConnection, makes it
  # the active connection, and returns it.
  #
  #    production_api2 = JSS.new_api_connection(
  #      name: 'prod2',
  #      server: 'prodserver.address.org',
  #      user: 'produser',
  #      pw: :prompt
  #    )
  #
  #   JSS.api.name  # => 'prod2'
  #
  # == Passing an APIConnection object to API-related methods
  #
  # All methods that use the API can take an 'api:' parameter which
  # contains an APIConnection object. When provided, that APIconnection is
  # used rather than the active connection.
  #
  # For example:
  #
  #   prod2_computer_sns = JSS::Computer.all_serial_numbers, api: production_api2
  #
  #   # the list of all computer serial numbers is read from the connection in
  #   # the variable 'production_api2' and stored in 'prod2_computer_sns'
  #
  #   prod2_victim_md = JSS::MobileDevice.fetch id: 832, api: production_api2
  #
  #   # the variable 'prod2_victim_md' now contains a JSS::MobileDevice queried
  #   # through the connection 'production_api2'.
  #
  # == Low-level use of APIConnection instances.
  #
  # For most cases, using APIConnection instances as mentioned above
  # is all you'll need. However to access API resources that aren't yet
  # implemented in other parts of ruby-jss, you can use the methods
  # {#get_rsrc}, {#put_rsrc}, {#post_rsrc}, & {#delete_rsrc}
  # documented below.
  #
  # For even lower-level work, you can access the underlying Faraday::Connection
  # inside the APIConnection via the connection's {#cnx} attribute.
  #
  # APIConnection instances also have a {#server} attribute which contains an
  # instance of {JSS::Server} q.v., representing the JSS to which it's connected.
  #
  class APIConnection

    # Class Constants
    #####################################

    # The base API path in the jss URL
    RSRC_BASE = 'JSSResource'.freeze

    # A url path to load to see if there's an API available at a host.
    # This just loads the API resource docs page
    TEST_PATH = "#{RSRC_BASE}/accounts".freeze

    # If the test path loads correctly from a casper server, it'll contain
    # this text (this is what we get when we make an unauthenticated
    # API call.)
    TEST_CONTENT = '<p>The request requires user authentication</p>'.freeze

    # The Default port
    HTTP_PORT = 9006

    # The Jamf default SSL port, default for locally-hosted servers
    SSL_PORT = 8443

    # The https default SSL port, default for Jamf Cloud servers
    HTTPS_SSL_PORT = 443

    # if either of these is specified, we'll default to SSL
    SSL_PORTS = [SSL_PORT, HTTPS_SSL_PORT].freeze

    # Recognize Jamf Cloud servers
    JAMFCLOUD_DOMAIN = 'jamfcloud.com'.freeze

    # JamfCloud connections default to 443, not 8443
    JAMFCLOUD_PORT = HTTPS_SSL_PORT

    # The top line of an XML doc for submitting data via API
    XML_HEADER = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'.freeze

    # Default timeouts in seconds
    DFT_OPEN_TIMEOUT = 60
    DFT_TIMEOUT = 60

    # The Default SSL Version
    DFT_SSL_VERSION = 'TLSv1_2'.freeze

    RSRC_NOT_FOUND_MSG = 'The requested resource was not found'.freeze

    # These classes are extendable, and may need cache flushing for EA definitions
    EXTENDABLE_CLASSES = [JSS::Computer, JSS::MobileDevice, JSS::User].freeze

    # values for the format param of get_rsrc
    GET_FORMATS = %i[json xml].freeze

    HTTP_ACCEPT_HEADER = 'Accept'.freeze
    HTTP_CONTENT_TYPE_HEADER = 'Content-Type'.freeze

    MIME_JSON = 'application/json'.freeze
    MIME_XML = 'application/xml'.freeze

    # Attributes
    #####################################

    # @return [String] the username who's connected to the JSS API
    attr_reader :user
    alias jss_user user

    # @return [Faraday::Connection] the underlying connection resource
    attr_reader :cnx

    # @return [Boolean] are we connected right now?
    attr_reader :connected
    alias connected? connected

    # @return [JSS::Server] the details of the JSS to which we're connected.
    attr_reader :server

    # @return [String] the hostname of the JSS to which we're connected.
    attr_reader :server_host

    # @return [String] any path in the URL below the hostname. See {#connect}
    attr_reader :server_path

    # @return [Integer] the port used for the connection
    attr_reader :port

    # @return [String] the protocol being used: http or https
    attr_reader :protocol

    # @return [Faraday::Response] The response from the most recent API call
    attr_reader :last_http_response

    # @return [String] The base URL to to the current REST API
    attr_reader :rest_url

    # @return [String,Symbol] an arbitrary name that can be given to this
    # connection during initialization, using the name: parameter.
    # defaults to user@hostname:port
    attr_reader :name

    # @return [Hash]
    # This Hash caches the result of the the first API query for an APIObject
    # subclass's .all summary list, keyed by the subclass's RSRC_LIST_KEY.
    # See the APIObject.all class method.
    #
    # It also holds related data items for speedier processing:
    #
    # - The Hashes created by APIObject.map_all_ids_to(foo), keyed by
    #   "#{RSRC_LIST_KEY}_map_#{other_key}".to_sym
    #
    # - This hash also holds a cache of the rarely-used APIObject.all_objects
    #   hash, keyed by "#{RSRC_LIST_KEY}_objects".to_sym
    #
    #
    # When APIObject.all, and related methods are called without an argument,
    # and this hash has a matching value, the value is returned, rather than
    # requerying the API. The first time a class calls .all, or whnever refresh
    # is not false, the API is queried and the value in this hash is updated.
    attr_reader :object_list_cache

    # @return [Hash{Class: Hash{String => JSS::ExtensionAttribute}}]
    # This Hash caches the Extension Attribute
    # definition objects for the three types of ext. attribs:
    # ComputerExtensionAttribute, MobileDeviceExtensionAttribute, and
    # UserExtensionAttribute, whenever they are fetched for parsing or
    # validating extention attribute data.
    #
    # The top-level keys are the EA classes themselves:
    # - ComputerExtensionAttribute
    # - MobileDeviceExtensionAttribute
    # - UserExtensionAttribute
    #
    # These each point to a Hash of their instances, keyed by name, e.g.
    #   {
    #    "A Computer EA" => <JSS::ComputerExtensionAttribute...>,
    #    "A different Computer EA" => <JSS::ComputerExtensionAttribute...>,
    #    ...
    #   }
    #
    attr_reader :ext_attr_definition_cache

    # Constructor
    #####################################

    # If name: is provided (as a String or Symbol) that will be
    # stored as the APIConnection's name attribute.
    #
    # For other available parameters, see {#connect}.
    #
    # If they are provided, they will be used to establish the
    # connection immediately.
    #
    # If not, you must call {#connect} before accessing the API.
    #
    def initialize(args = {})
      @name = args.delete :name
      @name ||= :unknown
      @connected = false
      @object_list_cache = {}
      connect args unless args.empty?
    end # init

    # Instance Methods
    #####################################

    # Connect to the JSS Classic API.
    #
    # @param args[Hash] the keyed arguments for connection.
    #
    # @option args :server[String] the hostname of the JSS API server, required if not defined in JSS::CONFIG
    #
    # @option args :server_path[String] If your JSS is not at the root of the server, e.g.
    #   if it's at
    #     https://myjss.myserver.edu:8443/dev_mgmt/jssweb
    #   rather than
    #     https://myjss.myserver.edu:8443/
    #   then use this parameter to specify the path below the root e.g:
    #     server_path: 'dev_mgmt/jssweb'
    #
    # @option args :port[Integer] the port number to connect with, defaults to 8443
    #
    # @option args :use_ssl[Boolean] should the connection be made over SSL? Defaults to true.
    #
    # @option args :verify_cert[Boolean] should HTTPS SSL certificates be verified. Defaults to true.
    #
    # @option args :user[String] a JSS user who has API privs, required if not defined in JSS::CONFIG
    #
    # @option args :pw[String,Symbol] Required, the password for that user, or :prompt, or :stdin
    #   If :prompt, the user is promted on the commandline to enter the password for the :user.
    #   If :stdin#, the password is read from a line of std in represented by the digit at #,
    #   so :stdin3 reads the passwd from the third line of standard input. defaults to line 1,
    #   if no digit is supplied. see {JSS.stdin}
    #
    # @option args :open_timeout[Integer] the number of seconds to wait for an initial response, defaults to 60
    #
    # @option args :timeout[Integer] the number of seconds before an API call times out, defaults to 60
    #
    # @return [true]
    #
    def connect(args = {})
      # new connections always get new caches
      flushcache

      args[:no_port_specified] = args[:port].to_s.empty?
      args = apply_connection_defaults args
      @timeout = args[:timeout]
      @open_timeout = args[:open_timeout]

      # ensure an integer
      args[:port] &&= args[:port].to_i

      # confirm we know basics
      verify_basic_args args

      # parse our ssl situation
      verify_ssl args

      @user = args[:user]

      @rest_url = build_rest_url args

      # figure out :password from :pw
      args[:password] = acquire_password args

      # heres our connection
      @cnx = create_connection args[:password]

      verify_server_version

      @name = "#{@user}@#{@server_host}:#{@port}" if @name.nil? || @name == :disconnected
      @connected ? hostname : nil
    end # connect

    # A useful string about this connection
    #
    # @return [String]
    #
    def to_s
      @connected ? "Using #{@rest_url} as user #{@user}" : 'not connected'
    end

    # Reset the response timeout for the rest connection
    #
    # @param timeout[Integer] the new timeout in seconds
    #
    # @return [void]
    #
    def timeout=(timeout)
      @cnx.options[:timeout] = timeout
    end

    # Reset the open-connection timeout for the rest connection
    #
    # @param timeout[Integer] the new timeout in seconds
    #
    # @return [void]
    #
    def open_timeout=(timeout)
      @cnx.options[:open_timeout] = timeout
    end

    # With a REST connection, there isn't any real "connection" to disconnect from
    # So to disconnect, we just unset all our credentials.
    #
    # @return [void]
    #
    def disconnect
      @user = nil
      @rest_url = nil
      @server_host = nil
      @cnx = nil
      @connected = false
    end # disconnect

    # Get a JSS resource
    # The first argument is the resource to get (the part of the API url
    # after the 'JSSResource/' ) The resource must be properly URL escaped
    # beforehand. Note: URL.encode is deprecated, use CGI.escape
    #
    # By default we get the data in JSON, and parse it into a ruby Hash
    # with symbolized Hash keys.
    #
    # If the second parameter is :xml then the XML version is retrieved and
    # returned as a String.
    #
    # To get the raw JSON string as it comes from the API, pass raw_json: true
    #
    # @param rsrc[String] the resource to get
    #   (the part of the API url after the 'JSSResource/' )
    #
    # @param format[Symbol] either ;json or :xml
    #   If the second argument is :xml, the XML data is returned as a String.
    #
    # @param raw_json[Boolean] When GETting JSON, return the raw unparsed string
    #   (the XML is always returned as a raw string)
    #
    # @return [Hash,String] the result of the get
    #
    def get_rsrc(rsrc, format = :json, raw_json: false)
      validate_connected
      raise JSS::InvalidDataError, 'format must be :json or :xml' unless GET_FORMATS.include? format

      @last_http_response =
        @cnx.get(rsrc) do |req|
          req.headers[HTTP_ACCEPT_HEADER] = format == :json ? MIME_JSON : MIME_XML
        end

      unless @last_http_response.success?
        handle_http_error
        return
      end

      return JSON.parse(@last_http_response.body, symbolize_names: true) if format == :json && !raw_json

      @last_http_response.body
    end

    # Update an existing JSS resource
    #
    # @param rsrc[String] the API resource being changed, the URL part after 'JSSResource/'
    #
    # @param xml[String] the xml specifying the changes.
    #
    # @return [String] the xml response from the server.
    #
    def put_rsrc(rsrc, xml)
      validate_connected

      # convert CRs & to &#13;
      xml.gsub!(/\r/, '&#13;')

      # send the data
      @last_http_response =
        @cnx.put(rsrc) do |req|
          req.headers[HTTP_CONTENT_TYPE_HEADER] = MIME_XML
          req.headers[HTTP_ACCEPT_HEADER] = MIME_XML
          req.body = xml
        end
      unless @last_http_response.success?
        handle_http_error
        return
      end

      @last_http_response.body
    end

    # Create a new JSS resource
    #
    # @param rsrc[String] the API resource being created, the URL part after 'JSSResource/'
    #
    # @param xml[String] the xml specifying the new object.
    #
    # @return [String] the xml response from the server.
    #
    def post_rsrc(rsrc, xml)
      validate_connected

      # convert CRs & to &#13;
      xml&.gsub!(/\r/, '&#13;')

      # send the data
      @last_http_response =
        @cnx.post(rsrc) do |req|
          req.headers[HTTP_CONTENT_TYPE_HEADER] = MIME_XML
          req.headers[HTTP_ACCEPT_HEADER] = MIME_XML
          req.body = xml
        end
      unless @last_http_response.success?
        handle_http_error
        return
      end
      @last_http_response.body
    end # post_rsrc

    # Delete a resource from the JSS
    #
    # @param rsrc[String] the resource to create, the URL part after 'JSSResource/'
    #
    # @return [String] the xml response from the server.
    #
    def delete_rsrc(rsrc)
      validate_connected
      raise MissingDataError, 'Missing :rsrc' if rsrc.nil?

      # delete the resource
      @last_http_response =
        @cnx.delete(rsrc) do |req|
          req.headers[HTTP_CONTENT_TYPE_HEADER] = MIME_XML
          req.headers[HTTP_ACCEPT_HEADER] = MIME_XML
        end

      unless @last_http_response.success?
        handle_http_error
        return
      end

      @last_http_response.body
    end # delete_rsrc

    # Test that a given hostname & port is a JSS API server
    #
    # @param server[String] The hostname to test,
    #
    # @param port[Integer] The port to try connecting on
    #
    # @return [Boolean] does the server host a JSS API?
    #
    def valid_server?(server, port = SSL_PORT)
      # cheating by shelling out to curl, because getting open-uri, or even net/http to use
      # ssl_options like :OP_NO_SSLv2 and :OP_NO_SSLv3 will take time to figure out..
      return true if `/usr/bin/curl -s 'https://#{server}:#{port}/#{TEST_PATH}'`.include? TEST_CONTENT
      return true if `/usr/bin/curl -s 'http://#{server}:#{port}/#{TEST_PATH}'`.include? TEST_CONTENT

      false
    end

    # The server to which we are connected, or will
    # try connecting to if none is specified with the
    # call to #connect
    #
    # @return [String] the hostname of the server
    #
    def hostname
      return @server_host if @server_host

      srvr = JSS::CONFIG.api_server_name
      srvr ||= JSS::Client.jss_server
      srvr
    end
    alias host hostname

    # Empty all cached lists from this connection
    # then run garbage collection to clear any available memory
    #
    # If an APIObject Subclass's RSRC_LIST_KEY is specified, only the caches
    # for that class are flushed (e.g. :computers, :comptuer_groups)
    #
    # NOTE if you've referenced objects in these caches, those objects
    # won't be removed from memory, but all cached data will be recached
    # as needed.
    #
    # @param key[Symbol, Class] Flush only the caches for the given RSRC_LIST_KEY. or
    #   the EAdef cache for the given extendable class. If nil (the default)
    #   flushes all caches
    #
    # @return [void]
    #
    def flushcache(key = nil)
      if EXTENDABLE_CLASSES.include? key
        @ext_attr_definition_cache[key] = {}
      elsif key
        map_key_pfx = "#{key}_map_"
        @object_list_cache.delete_if do |cache_key, _cache|
          cache_key == key || cache_key.to_s.start_with?(map_key_pfx)
        end
        @ext_attr_definition_cache
      else
        @object_list_cache = {}
        @ext_attr_definition_cache = {}
      end

      GC.start
    end

    # Remove the various cached data
    # from the instance_variables used to create
    # pretty-print (pp) output.
    #
    # @return [Array] the desired instance_variables
    #
    def pretty_print_instance_variables
      vars = instance_variables.sort
      vars.delete :@object_list_cache
      vars.delete :@last_http_response
      vars.delete :@network_ranges
      vars.delete :@my_distribution_point
      vars.delete :@master_distribution_point
      vars.delete :@ext_attr_definition_cache
      vars
    end

    # Private Insance Methods
    ####################################
    private

    # raise exception if not connected
    def validate_connected
      raise JSS::InvalidConnectionError, "Connection '#{@name}' Not Connected. Use .connect first." unless connected?
    end

    # Apply defaults from the JSS::CONFIG,
    # then from the JSS::Client,
    # then from the module defaults
    # to the args for the #connect method
    #
    # @param args[Hash] The args for #connect
    #
    # @return [Hash] The args with defaults applied
    #
    def apply_connection_defaults(args)
      apply_defaults_from_config(args)
      apply_defaults_from_client(args)
      apply_module_defaults(args)
    end

    # Apply defaults from the JSS::CONFIG
    # to the args for the #connect method
    #
    # @param args[Hash] The args for #connect
    #
    # @return [Hash] The args with defaults applied
    #
    def apply_defaults_from_config(args)
      # settings from config if they aren't in the args
      args[:server] ||= JSS::CONFIG.api_server_name
      args[:port] ||= JSS::CONFIG.api_server_port
      args[:user] ||= JSS::CONFIG.api_username
      args[:timeout] ||= JSS::CONFIG.api_timeout
      args[:open_timeout] ||= JSS::CONFIG.api_timeout_open
      args[:ssl_version] ||= JSS::CONFIG.api_ssl_version

      # if verify cert was not in the args, get it from the prefs.
      # We can't use ||= because the desired value might be 'false'
      args[:verify_cert] = JSS::CONFIG.api_verify_cert if args[:verify_cert].nil?
      args
    end # apply_defaults_from_config

    # Apply defaults from the JSS::Client
    # to the args for the #connect method
    #
    # @param args[Hash] The args for #connect
    #
    # @return [Hash] The args with defaults applied
    #
    def apply_defaults_from_client(args)
      return unless JSS::Client.installed?

      # these settings can come from the jamf binary config, if this machine is a JSS client.
      args[:server] ||= JSS::Client.jss_server
      args[:port] ||= JSS::Client.jss_port.to_i
      args[:use_ssl] ||= JSS::Client.jss_protocol.to_s.end_with? 's'
      args
    end

    # Apply the module defaults to the args for the #connect method
    #
    # @param args[Hash] The args for #connect
    #
    # @return [Hash] The args with defaults applied
    #
    def apply_module_defaults(args)
      args[:port] = args[:server].to_s.end_with?(JAMFCLOUD_DOMAIN) ? JAMFCLOUD_PORT : SSL_PORT if args[:no_port_specified]
      args[:timeout] ||= DFT_TIMEOUT
      args[:open_timeout] ||= DFT_OPEN_TIMEOUT
      args[:ssl_version] ||= DFT_SSL_VERSION
      args
    end

    # Raise execeptions if we don't have essential data for the connection
    #
    # @param args[Hash] The args for #connect
    #
    # @return [void]
    #
    def verify_basic_args(args)
      # must have server, user, and pw
      raise JSS::MissingDataError, 'No JSS :server specified, or in configuration.' unless args[:server]
      raise JSS::MissingDataError, 'No JSS :user specified, or in configuration.' unless args[:user]
      raise JSS::MissingDataError, "Missing :pw for user '#{args[:user]}'" unless args[:pw]
    end

    # Verify that we can connect with the args provided, and that
    # the server version is high enough for this version of ruby-jss.
    #
    # This makes the first API GET call and will raise an exception if things
    # are wrong, like failed authentication. Will also raise an exception
    # if the JSS version is too low
    # (see also JSS::Server)
    #
    # @return [void]
    #
    def verify_server_version
      @connected = true

      # the jssuser resource is readable by anyone with a JSS acct
      # regardless of their permissions.
      # However, it's marked as 'deprecated'. Hopefully jamf will
      # keep this basic level of info available for basic authentication
      # and JSS version checking.
      begin
        data = get_rsrc('jssuser')
      rescue JSS::AuthorizationError
        raise JSS::AuthenticationError, "Incorrect JSS username or password for '#{@user}@#{@server_host}:#{@port}'."
      end

      @server = JSS::Server.new data[:user], self

      min_vers = JSS.parse_jss_version(JSS::MINIMUM_SERVER_VERSION)[:version]
      return if @server.version >= min_vers # we're good...

      err_msg = "JSS version #{@server.raw_version} to low. Must be >= #{min_vers}"
      @connected = false
      raise JSS::UnsupportedError, err_msg
    end

    # Build the base URL for the API connection
    #
    # @param args[Hash] The args for #connect
    #
    # @return [String] The URI encoded URL
    #
    def build_rest_url(args)
      @server_host = args[:server]
      @port = args[:port].to_i

      # trim any potential  leading slash on server_path, ensure a trailing slash
      if args[:server_path]
        @server_path = args[:server_path]
        @server_path = @server_path[1..-1] if @server_path.start_with? '/'
        @server_path << '/' unless @server_path.end_with? '/'
      end

      # we're using ssl if:
      #  1) args[:use_ssl] is anything but false
      # or
      #  2) the port is a known ssl port.
      args[:use_ssl] = args[:use_ssl] != false || SSL_PORTS.include?(@port)

      @protocol = 'http'
      @protocol << 's' if args[:use_ssl]
      # and here's the URL
      "#{@protocol}://#{@server_host}:#{@port}/#{@server_path}#{RSRC_BASE}"
    end

    # From whatever was given in args[:pw], figure out the real password
    #
    # @param args[Hash] The args for #connect
    #
    # @return [String] The password for the connection
    #
    def acquire_password(args)
      if args[:pw] == :prompt
        JSS.prompt_for_password "Enter the password for JSS user #{args[:user]}@#{args[:server]}:"
      elsif args[:pw].is_a?(Symbol) && args[:pw].to_s.start_with?('stdin')
        args[:pw].to_s =~ /^stdin(\d+)$/
        line = Regexp.last_match(1)
        line ||= 1
        JSS.stdin line
      else
        args[:pw]
      end
    end

    # Get the appropriate OpenSSL::SSL constant for
    # certificate verification.
    #
    # @param args[Hash] The args for #connect
    #
    # @return [Type] description_of_returned_object
    #
    def verify_ssl(args)
      # use SSL for SSL ports unless specifically told not to
      if SSL_PORTS.include? args[:port]
        args[:use_ssl] = true unless args[:use_ssl] == false
      end
      return unless args[:use_ssl]

      # if verify_cert is anything but false, we will verify
      args[:verify_ssl] = args[:verify_cert] != false

      # ssl version if not specified
      args[:ssl_version] ||= DFT_SSL_VERSION

      @ssl_options = {
        verify: args[:verify_ssl],
        version: args[:ssl_version]
      }
    end

    # Parses the @last_http_response
    # and raises a JSS::APIError with a useful error message.
    #
    # @return [void]
    #
    def handle_http_error
      return if @last_http_response.success?

      case @last_http_response.status
      when 404
        err = JSS::NoSuchItemError
        msg = 'Not Found'
      when 409
        err = JSS::ConflictError
        @last_http_response.body =~ /<p>(The server has not .*?)(<|$)/m
        Regexp.last_match(1) ||  @last_http_response.body =~ %r{<p>Error: (.*?)</p>}
        msg = Regexp.last_match(1)
      when 400
        err = JSS::BadRequestError
        @last_http_response.body =~ %r{>Bad Request</p>\n<p>(.*?)</p>\n<p>You can get technical detail}m
        msg = Regexp.last_match(1)
      when 401
        err = JSS::AuthorizationError
        msg = 'You are not authorized to do that.'
      when (500..599)
        err = JSS::APIRequestError
        msg = 'There was an internal server error'
      else
        err = JSS::APIRequestError
        msg = "There was a error processing your request, status: #{@last_http_response.status}"
      end
      raise err, msg
    end

    # create the faraday connection object
    def create_connection(pw)
      Faraday.new(@rest_url, ssl: @ssl_options) do |cnx|
        cnx.basic_auth @user, pw
        cnx.options[:timeout] = @timeout
        cnx.options[:open_timeout] = @open_timeout
        cnx.adapter Faraday::Adapter::NetHttp
      end
    end

  end # class APIConnection

  # JSS MODULE METHODS
  ######################

  # Create a new APIConnection object and use it for all
  # future API calls. If connection options are provided,
  # they are passed to the connect method immediately, otherwise
  # JSS.api.connect must be called before attemting to use the
  # connection.
  #
  # @param (See JSS::APIConnection#connect)
  #
  # @return [APIConnection] the new, active connection
  #
  def self.new_api_connection(args = {})
    args[:name] ||= :default
    @api = APIConnection.new args
  end

  # Switch the connection used for all API interactions to the
  # one provided. See {JSS::APIConnection} for details and examples
  # of using multiple connections
  #
  # @param connection [APIConnection] The APIConnection to use for future
  #   API calls. If omitted, use the default connection created when ruby-jss
  #   was loaded (which may or may not yet be connected)
  #
  # @return [APIConnection] The connection now being used.
  #
  def self.use_api_connection(connection)
    raise 'API connections must be instances of JSS::APIConnection' unless connection.is_a? JSS::APIConnection

    @api = connection
  end

  # Make the default connection (Stored in JSS::API) active
  #
  # @return [void]
  #
  def self.use_default_connection
    use_api_connection @api
  end

  # The currently active JSS::APIConnection instance.
  #
  # @return [JSS::APIConnection]
  #
  def self.api
    @api ||= APIConnection.new name: :default
  end

  # aliases of module methods
  class << self

    alias api_connection api
    alias connection api
    alias active_connection api

    alias new_connection new_api_connection
    alias new_api new_api_connection

    alias use_api use_api_connection
    alias use_connection use_api_connection
    alias activate_connection use_api_connection

  end

  # create the default connection
  new_api_connection unless @api

  # Save the default connection in the API constant,
  # mostly for backward compatibility.
  API = @api unless defined? API

end # module
