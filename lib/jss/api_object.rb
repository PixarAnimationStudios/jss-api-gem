module JSS

  #####################################
  ### Module Variables
  #####################################

  #####################################
  ### Module Methods
  #####################################

  #####################################
  ### Classes
  #####################################

  ###
  ### This class is the parent to all JSS API objects. It provides standard methods and structures
  ### that apply to all API resouces.
  ###
  ### See the README.md file for general info about using subclasses of JSS::APIObject
  ###
  ### == Subclassing
  ###
  ### === Constructor
  ###
  ### In general, subclasses should do any class-specific argument checking before
  ### calling super, and then afterwards, use the contents of @init_data to populate
  ### any class-specific attributes. @id, @name, @rest_rsrc, and @in_jss are handled here.
  ###
  ### If a subclass can be looked up by some key other than :name or :id, the subclass must
  ### pass the keys as an Array in the second argument when calling super from #initialize.
  ### See JSS::Computer#initialize for an example of how to implement this feature.
  ###
  ### === Object Creation
  ###
  ### If a subclass should be able to be created in the JSS be sure to include JSS::Creatable
  ###
  ### The constructor should verify any extra required data (aside from :name) in the args before or after
  ### calling super.
  ###
  ### See JSS::Creatable for more details.
  ###
  ### === Object Modification
  ###
  ### If a subclass should be modifiable in the JSS, include JSS::Updatable, q.v. for details.
  ###
  ### === Object Deletion
  ###
  ### All subclasses can be deleted in the JSS.
  ###
  ### === Required Constants
  ###
  ### Subclasses *must* provide certain Constants in order to correctly interpret API data and
  ### communicate with the API.
  ###
  ### ==== RSRC_BASE = [String],  The base for REST resources of this class
  ###
  ### e.g. 'computergroups' in  "https://casper.mycompany.com:8443/JSSResource/computergroups/id/12"
  ###
  ### ==== RSRC_LIST_KEY = [Symbol] The Hash key for the JSON list output of all objects of this class in the JSS.
  ###
  ### e.g. the JSON output of resource "JSSResource/computergroups" is a hash
  ### with one item (an Array of computergroups). That item's key is the Symbol :computer_groups
  ###
  ### ==== RSRC_OBJECT_KEY = [Symbol] The Hash key used for individual JSON object output.
  ### It's also used in various error messages
  ###
  ### e.g. the JSON output of the resource "JSSResource/computergroups/id/436" is
  ### a hash with one item (another hash with details of one computergroup).
  ### That item's key is the Symbol :computer_group
  ###
  ### ==== VALID_DATA_KEYS = [Array<Symbol>] The Hash keys used to verify validity of :data
  ### When instantiating a subclass using :data => somehash, some minimal checks are performed
  ### to ensure the data is valid for the subclass
  ###
  ### The Symbols in this Array are compared to the keys of the hash provided.
  ### If any of these don't exist in the hash's keys, then the :data is
  ### not valid and an exception is raised.
  ###
  ### The keys :id and :name must always exist in the hash.
  ### If only :id and :name are valid, VALID_DATA_KEYS should be an empty array.
  ###
  ### e.g. for a department, only :id and :name are valid, so VALID_DATA_KEYS is an empty Array ([])
  ### but for a computer group, the keys :computers and :is_smart must be present as well.
  ### so VALID_DATA_KEYS will be [:computers, :is_smart]
  ###
  ### *NOTE* Some API objects have data broken into subsections, in which case the
  ### VALID_DATA_KEYS are expected in the section :general.
  ###
  class APIObject

    #####################################
    ### Mix-Ins
    #####################################

    #####################################
    ### Class Variables
    #####################################

    ###
    ### This Hash holds the most recent API query for a list of all items in any subclass,
    ### keyed by the subclass's RSRC_LIST_KEY. See the self.all class method.
    ###
    ### When the .all method is called without an argument, and this hash has
    ### a matching value, the value is returned, rather than requerying the
    ### API. The first time a class calls .all, or whnever refresh is
    ### not false, the API is queried and the value in this hash is updated.
    ###
    @@all_items = {}

    #####################################
    ### Class Methods
    #####################################

    ###
    ### Return an Array of Hashes for all objects of this subclass in the JSS.
    ###
    ### This method is only valid in subclasses of JSS::APIObject, and is
    ### the parsed JSON output of an API query for the resource defined in the subclass's RSRC_BASE,
    ### e.g. for JSS::Computer, with the RSRC_BASE of :computers,
    ### This method retuens the output of the 'JSSResource/computers' resource,
    ### which is a list of all computers in the JSS.
    ###
    ### Each item in the Array is a Hash with at least two keys, :id and :name.
    ### The class methods .all_ids and .all_names provide easier access to those data
    ### as mapped Arrays.
    ###
    ### Some API classes provide other data in each Hash, e.g. :udid (for computers
    ### and mobile devices) or :is_smart (for groups).
    ###
    ### Subclasses implementing those API classes should provide .all_xxx
    ### class methods for accessing those other values as mapped Arrays,
    ### e.g. JSS::Computer.all_udids
    ###
    ### The results of the first query for each subclass is stored in @@all_items
    ### and returned at every future call, so as to not requery the server every time.
    ###
    ### To force requerying to get updated data, provided a non-false argument.
    ### I usually use :refresh, so that it's obvious what I'm doing, but true, 1,
    ### or anything besides false or nil will work.
    ###
    ### @param refresh[true,false] should the data be re-queried from the API?
    ###
    ### @return [Array<Hash{:name=>String, :id=> Integer}>]
    ###
    def self.all(refresh = false)
      raise JSS::UnsupportedError, ".all can only be called on subclasses of JSS::APIObject" if self == JSS::APIObject
      @@all_items[self::RSRC_LIST_KEY] = nil if refresh
      return @@all_items[self::RSRC_LIST_KEY] if @@all_items[self::RSRC_LIST_KEY]
      @@all_items[self::RSRC_LIST_KEY] = JSS::API.get_rsrc(self::RSRC_BASE)[self::RSRC_LIST_KEY]
    end

    ###
    ### Returns an Array of the JSS id numbers of all the members
    ### of the subclass.
    ###
    ### e.g. When called from subclass JSS::Computer,
    ### returns the id's of all computers in the JSS
    ###
    ### @param refresh[true,false] should the data be re-queried from the API?
    ###
    ### @return [Array<Integer>] the ids of all items of this subclass in the JSS
    ###
    def self.all_ids(refresh = false)
      self.all(refresh).map{|i| i[:id]}
    end

        ###
    ### Returns an Array of the JSS names of all the members
    ### of the subclass.
    ###
    ### e.g. When called from subclass JSS::Computer,
    ### returns the names of all computers in the JSS
    ###
    ### @param refresh[true,false] should the data be re-queried from the API?
    ###
    ### @return [Array<String>] the names of all item of this subclass in the JSS
    ###
    def self.all_names(refresh = false)
      self.all(refresh).map{|i| i[:name]}
    end

    ###
    ### Return a hash of all objects of this subclass
    ### in the JSS where the key is the id, and the value
    ### is some other key in the data items returned by the JSS::APIObject.all.
    ###
    ### If the other key doesn't exist in the API
    ### data, (eg :udid for JSS::Department) the values will be nil.
    ###
    ### Use this method to map ID numbers to other identifiers returned
    ### by the API list resources. Invert its result to map the other
    ### identfier to ids.
    ###
    ### @example
    ###   JSS::Computer.map_all_ids_to(:name)
    ###
    ###   # Returns, eg {2 => "kimchi", 5 => "mantis"}
    ###
    ###   JSS::Computer.map_all_ids_to(:name).invert
    ###
    ###   # Returns, eg {"kimchi" => 2, "mantis" => 5}
    ###
    ### @param other_key[Symbol] the other data key with which to associate each id
    ### @param refresh[true,false] should the data  re-queried from the API?
    ###
    ### @return [Hash{Integer => Oject}] the associated ids and data
    ###
    def self.map_all_ids_to(other_key, refresh = false)
      h = {}
      self.all(refresh).each{|i| h[i[:id]] = i[other_key]}
      h
    end

    ###
    ### Convert an Array of Hashes of API object data to a
    ### REXML element.
    ###
    ### Given an Array of Hashes of items in the subclass
    ### where each Hash has at least an :id  or a :name key,
    ### (as what comes from the .all class method)
    ### return a REXML <classes> element
    ### with one <class> element per Hash member.
    ###
    ### @example
    ###   # for class JSS::Computer
    ###   some_comps = [{:id=>2, :name=>"kimchi"},{:id=>5, :name=>"mantis"}]
    ###   xml_names = JSS::Computer.xml_list some_comps
    ###   puts xml_names  # output manually formatted for clarity, xml.to_s has no newlines between elements
    ###
    ###   <computers>
    ###     <computer>
    ###       <name>kimchi</name>
    ###     </computer>
    ###     <computer>
    ###       <name>mantis</name>
    ###     </computer>
    ###   </computers>
    ###
    ###   xml_ids = JSS::Computer.xml_list some_comps, :id
    ###   puts xml_names  # output manually formatted for clarity, xml.to_s has no newlines between elements
    ###
    ###   <computers>
    ###     <computer>
    ###       <id>2</id>
    ###     </computer>
    ###     <computer>
    ###       <id>5</id>
    ###     </computer>
    ###   </computers>
    ###
    ### @param array[Array<Hash{:name=>String, :id =>Integer, Symbol=>#to_s}>] the Array of subclass data to convert
    ### @param content[Symbol] the Hash key to use as the inner element for each member of the Array
    ###
    ### @return [REXML::Element] the XML element representing the data
    ###
    def self.xml_list(array, content = :name)
      JSS.item_list_to_rexml_list self::RSRC_LIST_KEY, self::RSRC_OBJECT_KEY, array, content
    end

    #####################################
    ### Class Constants
    #####################################



    ###
    ### These Symbols are added to VALID_DATA_KEYS for performing the
    ### :data validity test described above.
    ###
    REQUIRED_DATA_KEYS = [:id, :name]

    ###
    ### By default, these keys are available for object lookups
    ### Others can be added by subclasses using an array of them
    ### as the second argument to super(initialize)
    ### The keys must be Symbols that  match the keyname in the resource url.
    ### e.g. :serialnumber  for JSSResource/computers/serialnumber/xxxxx
    ###
    DEFAULT_LOOKUP_KEYS = [:id, :name]

    #####################################
    ### Attributes
    #####################################

    ### Integer - the JSS id number
    attr_reader :id

    ### String - the name
    attr_reader :name

    ### Boolean - is it in the JSS?
    attr_reader :in_jss

    ### Boolean -  need to save any changes?
    attr_reader :need_to_update

    ### String - the Rest resource for API access
    ### (the part after "JSSResource/" )
    attr_reader :rest_rsrc

    #####################################
    ### Constructor
    #####################################

    ###
    ### See the JSS::APIObject overview for more details.
    ###
    ### @param args[Hash] the data for looking up, or constructing, a new object.
    ###   Must include :id, :name, or :data.
    ###   * :id or :name will be looked up via the API
    ###   * * if the subclass includes JSS::Creatable, :id can be :new, to create a new object in the JSS.
    ###   * :data must be the JSON output of a separate API query (a Hash of valid object data)
    ### @param other_lookup_keys[Array<Symbol>] Hash keys than :id and :name, by which an API
    ###   lookup may be performed.
    ###
    def initialize(args = {}, other_lookup_keys = [])

      ####### Previously looked-up JSON data
      if args[:data]

        @init_data = args[:data]
        ### Does this data come in subsets?
        @got_subsets = @init_data[:general].kind_of?(Hash)

        ### data must include all they keys in REQUIRED_DATA_KEYS + VALID_DATA_KEYS
        ### in either the main hash keys or the :general sub-hash, if it exists
        hash_to_check = @got_subsets ? @init_data[:general] : @init_data
        combined_valid_keys = self.class::REQUIRED_DATA_KEYS + self.class::VALID_DATA_KEYS
        keys_ok = (hash_to_check.keys & combined_valid_keys).count == combined_valid_keys.count
        raise JSS::InvalidDataError, ":data is not valid JSON for a #{self.class::RSRC_OBJECT_KEY} from the API. It needs at least the keys :#{combined_valid_keys.join ', :'}" unless keys_ok

        ### and the id must be in the jss
        raise NoSuchItemError, "No #{self.class::RSRC_OBJECT_KEY} with JSS id: #{@init_data[:id]}" unless  self.class.all_ids.include? hash_to_check[:id]


      ###### Make a new one in the JSS, but only if we've included the Creatable module
      elsif args[:id] == :new

        raise JSS::UnsupportedError, "Creating or editing #{self.class::RSRC_LIST_KEY} isn't yet supported. Please use other Casper workflows." unless self.class::CREATABLE

        raise JSS::MissingDataError, "You must provide a :name for a new #{self.class::RSRC_OBJECT_KEY}." unless args[:name]

        raise JSS::AlreadyExistsError, "A #{self.class::RSRC_OBJECT_KEY} already exists with the name '#{args[:name]}'" if self.class.all_names.include? args[:name]


        ### NOTE: subclasses may want to pre-populate more keys in @init_data when :id == :new
        ### then parse them into attributes later.
        @init_data = {
          :name => args[:name]
        }

      ###### Look up the data via the API
      else
        ### what lookup key are we using?
        combined_lookup_keys = self.class::DEFAULT_LOOKUP_KEYS + other_lookup_keys
        lookup_key = (combined_lookup_keys & args.keys)[0]

        raise JSS::MissingDataError, "Args must include :#{combined_lookup_keys.join(', :')}, or :data"  unless lookup_key

        rsrc = "#{self.class::RSRC_BASE}/#{lookup_key}/#{args[lookup_key]}"

        begin
          @init_data = JSS::API.get_rsrc(rsrc)[self.class::RSRC_OBJECT_KEY]
          ### Does this data come in subsets?
          @got_subsets = @init_data[:general].kind_of?(Hash)
        rescue RestClient::ResourceNotFound
          raise NoSuchItemError, "No #{self.class::RSRC_OBJECT_KEY} found matching: #{args[:name] ? args[:name] : args[:id]}"
        end
      end ## end arg parsing

      ### set the name and id, and remove empty strings
      if @got_subsets
        @id = @init_data[:general][:id]
        @name = @init_data[:general][:name]
        @site = @init_data[:general][:site] || JSS::NO_SITE
        @init_data.each_pair do |k,v|
          if v.kind_of?(Hash)
            v.delete_if{|kk,vv| vv == ''}
          else
            v = nil if v == ''
          end
        end

      else # no subsets
        @id = @init_data[:id]
        @name = @init_data[:name]
        @site = @init_data[:site] || JSS::NO_SITE
        @init_data.delete_if{|k,v| v == ''}

      end

      ### if we have a @id here, we're already in the JSS
      if @id
        @in_jss = true
        @rest_rsrc =  "#{self.class::RSRC_BASE}/id/#{@id}"
        @need_to_update = false
      else
        @in_jss = false
        @rest_rsrc = "#{self.class::RSRC_BASE}/name/#{URI.escape @name}"
        @need_to_update = true
      end

    end # init

    #####################################
    ### Public Instance Methods
    #####################################

    ###
    ### Delete this item from the JSS.
    ###
    ### Subclasses may want to redefine this method,
    ### first calling super, then setting other attributes to
    ### nil, false, empty, etc..
    ###
    def delete
      return nil unless @in_jss
      JSS::API.delete_rsrc @rest_rsrc
      @rest_rsrc = "#{self.class::RSRC_BASE}/name/#{URI.escape @name}"
      @id = nil
      @in_jss = false
      @need_to_update = true
    end # delete

    #####################################
    ### Private Instance Methods
    #####################################
    private

    ###
    ### Return a String with the XML Resource
    ### for submitting creation or changes to the JSS via
    ### the API
    ###
    ### Most classes will redefine this method.
    ###
    def rest_xml
      doc = REXML::Document.new APIConnection::XML_HEADER
      tmpl = doc.add_element self.class::RSRC_OBJECT_KEY.to_s
      tmpl.add_element('name').text = @name
      return doc.to_s
    end


  end # class APIObject



end # module JSS

### Mix-in Sub Modules
require "jss/api_object/creatable"
require "jss/api_object/file_upload"
require "jss/api_object/locatable"
require "jss/api_object/matchable"
require "jss/api_object/purchasable"
require "jss/api_object/updatable"

### Mix-in Sub Modules with Classes
require "jss/api_object/criteriable"
require "jss/api_object/scopable"

### APIObject SubClasses with SubClasses
require "jss/api_object/advanced_search"
require "jss/api_object/extension_attribute"
require "jss/api_object/group"
require "jss/api_object/report"

### APIObject SubClasses without SubClasses
require "jss/api_object/building"
require "jss/api_object/category"
require "jss/api_object/computer"
require "jss/api_object/department"
require "jss/api_object/distribution_point"
require "jss/api_object/mobile_device"
require "jss/api_object/netboot_server"
require "jss/api_object/network_segment"
require "jss/api_object/package"
require "jss/api_object/peripheral_type"
require "jss/api_object/peripheral"
require "jss/api_object/policy"
require "jss/api_object/removable_macaddr"
require "jss/api_object/script"
require "jss/api_object/software_update_server"
require "jss/api_object/user"

