# Copyright 2020 Pixar

#
#    Licensed under the Apache License, Version 2.0 (the "Apache License")
#    with the following modification; you may not use this file except in
#    compliance with the Apache License and the following modification to it:
#    Section 6. Trademarks. is deleted and replaced with:
#
#    6. Trademarks. This License does not grant permission to use the trade
#       names, trademarks, service marks, or product names of the Licensor
#       and its affiliates, except as required to comply with Section 4(c) of
#       the License and to reproduce the content of the NOTICE file.
#
#    You may obtain a copy of the Apache License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the Apache License with the above modification is
#    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#    KIND, either express or implied. See the Apache License for the specific
#    language governing permissions and limitations under the Apache License.
#
#

module JSS

  # Classes
  #####################################

  # This is the parent class of the smart/static group objects in the JSS
  # namely, {ComputerGroup}, {MobileDeviceGroup}, and {UserGroup}
  #
  # It provides methods for working with the membership of static groups and, by
  # including {JSS::Criteriable}, the criteria for smart groups.
  #
  # When changing the criteria of a smart group, use the #criteria attribute,
  # which is a {JSS::Criteria} instance.
  #
  # Subclasses must define these constants:
  # - MEMBER_CLASS: the ruby-jss class to which the group
  #   members belong (e.g. JSS::MobileDevice)
  # - ADD_MEMBERS_ELEMENT: the XML element tag for adding members to the group
  #   wuth a PUT call to the API, e.g. 'computer_additions'
  # - REMOVE_MEMBERS_ELEMENT: the XML element tag for removing members from the
  #   group wuth a PUT call to the API, e.g. 'computer_deletions'
  #
  # @see JSS::APIObject
  #
  # @see JSS::Criteriable
  #
  class Group < JSS::APIObject

    # Mix-Ins
    #####################################
    include JSS::Creatable
    include JSS::Updatable
    include JSS::Criteriable
    include JSS::Sitable

    # Class Constants
    #####################################

    # the types of groups allowed for creation
    GROUP_TYPES = %i[smart static].freeze

    # Where is the Site data in the API JSON?
    SITE_SUBSET = :top

    # the 'id' xml element tag
    ID_XML_TAG = 'id'.freeze

    # Class Methods
    #####################################

    # Returns an Array of all the smart
    # groups.
    #
    def self.all_smart(refresh = false, api: JSS.api)
      all(refresh, api: api).select { |g| g[:is_smart] }
    end

    # Returns an Array of all the static
    # groups.
    #
    def self.all_static(refresh = false, api: JSS.api)
      all(refresh, api: api).reject { |g| g[:is_smart] }
    end

    # Immediatly add and/or remove members in a static group without
    # instantiating it first. Uses the <x_additions> and <x_deletions>
    # XML elements available when sending a PUT request to the API.
    #
    # @param group [String, Integer] The name or id of the group being changed
    #
    # @param add_members [String, Integer, Array<String, Integer>] valid
    #   identifier(s) for members to add
    #
    # @param remove_members [String, Integer, Array<String, Integer>] valid
    #   identifier(s) for members to remove
    #
    # @param api [JSS::APIConnection] The API connetion to use, uses the default
    #   connection if not specified
    #
    # @return [void]
    #
    def self.change_membership(group, add_members: [], remove_members: [], api: JSS.api)
      raise JSS::NoSuchItemError, "No #{self} matching '#{group}'" unless (group_id = valid_id group, api: api)
      raise JSS::UnsupportedError, "Not a static group, can't change membership directly" if map_all_ids_to(:is_smart, api: api)[group_id]

      add_members = [add_members].flatten
      remove_members = [remove_members].flatten
      return if add_members.empty? && remove_members.empty?

      # we must know the current group membership, because the API
      # will raise a conflict error if we try to remove a member
      # that isn't in the group (which is kinda lame - it should just
      # ignore this, like it does when we add a member that's already
      # in the group.)
      current_member_ids = fetch(id: group_id).member_ids

      # nil if no changes to be made
      xml_doc = change_membership_xml add_members, remove_members, current_member_ids
      return unless xml_doc

      api.put_rsrc "#{self::RSRC_BASE}/id/#{group_id}", xml_doc.to_s
    end

    # return [REXML::Document, nil]
    #
    def self.change_membership_xml(add_members, remove_members, current_member_ids)
      # these are nil if there are no changes to make
      addx = member_additions_xml(add_members, current_member_ids)
      remx = member_removals_xml(remove_members, current_member_ids)
      return nil unless addx || remx

      doc = REXML::Document.new JSS::APIConnection::XML_HEADER
      groupelem = doc.add_element self::RSRC_OBJECT_KEY.to_s
      groupelem << addx if addx
      groupelem << remx if remx
      doc
    end
    private_class_method :change_membership_xml

    # @return [REXML::Element, nil]
    #
    def self.member_additions_xml(add_members, current_member_ids)
      return nil if add_members.empty?

      additions = REXML::Element.new self::ADD_MEMBERS_ELEMENT
      member_added = false
      add_members.each do |am|
        am_id = self::MEMBER_CLASS.valid_id am
        raise JSS::NoSuchItemError, "No #{self::MEMBER_CLASS} matching '#{am}'" unless am_id
        next if current_member_ids.include? am_id

        xam = additions.add_element self::MEMBER_CLASS::RSRC_OBJECT_KEY.to_s
        xam.add_element(ID_XML_TAG).text = am_id.to_s
        member_added = true
      end # each

      member_added ? additions : nil
    end
    private_class_method :member_additions_xml

    # @return [REXML::Element, nil]
    #
    def self.member_removals_xml(remove_members, current_member_ids)
      return nil if remove_members.empty?

      removals = REXML::Element.new self::REMOVE_MEMBERS_ELEMENT
      member_removed = false
      remove_members.each do |rm|
        rm_id = self::MEMBER_CLASS.valid_id rm
        next unless rm_id && current_member_ids.include?(rm_id)

        xrm = removals.add_element self::MEMBER_CLASS::RSRC_OBJECT_KEY.to_s
        xrm.add_element(ID_XML_TAG).text = rm_id.to_s
        member_removed = true
      end # each

      member_removed ? removals : nil
    end
    private_class_method :member_removals_xml


    # Attributes
    #####################################

    # @return [Array<Hash>] the group membership
    #
    # Each hash contains the identifiers for
    # a member of the group, those being:
    # - :id, :name, and possibly :udid, :serial_number, :mac_address, :alt_mac_address,  and :wifi_mac_address
    #
    # @see #member_ids
    #
    # @see #member_names
    #
    attr_reader :members

    # @return [Boolean] is this a smart group
    attr_reader :is_smart

    # @return [Boolean] does this group send notifications when it changes?
    attr_reader :notify_on_change


    # Constructor
    #####################################

    # When creating a new group in the JSS, you must call .make with a :type key
    # and a value of :smart or :static, as well as a :name
    #
    # @see JSS::APIObject
    #
    def initialize(args = {})
      if args[:id] == :new
        raise JSS::InvalidDataError, 'New group creation must specify a :type of :smart or :static' unless GROUP_TYPES.include? args[:type]
      end

      super args

      @is_smart = @init_data[:is_smart] || (args[:type] == :smart)

      @members =
        if @init_data[self.class::MEMBER_CLASS::RSRC_LIST_KEY]
          @init_data[self.class::MEMBER_CLASS::RSRC_LIST_KEY]
        else
          []
        end
    end # init

    # Public Instance Methods
    #####################################

    # @see Creatable#create
    #
    # @param calculate_members [Boolan] should the local membership list be
    #   re-read from the API after the group is created?
    #
    # @param retries [Integer] If calculate_members is true, refetching the
    #   group to re-read the membership can happen too fast, the JSS won't know
    #   it exists yet and will throw a NoSuchItem error.  If that
    #   happens, try again this many times with a 1 second pause between attempts.
    #
    def create(calculate_members: true, retries: 10)
      if @is_smart
        raise JSS::MissingDataError, 'No criteria specified for smart group' unless @criteria
      end
      super()

      if calculate_members
        tries = 0
        while tries < retries
          begin
            refresh_members
            break
          rescue
            sleep 1
            tries += 1
          end # begin
        end # while
      end # if calc members

      @id
    end

    # @see Updatable#update
    #
    def update(refresh: true)
      super()
      refresh_members if refresh
      @id
    end

    # Wrapper/alias for both create and update
    def save(**params)
      params[:calculate_members] = true if params[:calculate_members].nil?
      params[:retries] = 10 if params[:retries].nil?
      params[:refresh] = true if params[:refresh].nil?

      if @in_jss
        raise JSS::UnsupportedError, 'Updating this object in the JSS is currently not supported by ruby-jss' unless updatable?


        update refresh: params[:refresh]
      else
        raise JSS::UnsupportedError, 'Creating this object in the JSS is currently not supported by ruby-jss' unless creatable?
        create calculate_members: params[:calculate_members], retries: params[:retries]
      end
    end

    # @see APIObject#delete
    #
    def delete
      super
      @is_smart = nil
      @criteria = nil
      @site = nil
      @members = []
    end # delete

    # Apply a new set of criteria to a smart group
    #
    # @param new_criteria[JSS::Criteria] the new criteria for the smart group
    #
    def criteria=(new_criteria)
      raise InvalidDataError, 'Only smart groups have criteria.' unless @is_smart

      super
    end

    # Change static group to smart group
    #
    # @param args[Hash] the options and settings use for switching the computer group from static group to smart group
    #
    # @option args criteria[Array] The criterias to be user for the smart group
    def set_smart(*params)
      return if @is_smart

      params[:criteria] = [] if params[:criteria].nil?

      criteria = params[:criteria]

      @is_smart = true
      @need_to_update = true
    end

    # Change smart group to static group
    #
    # @param args[Hash] the options and settings use for switching the computer group from smart group to static group
    #
    # @option args preserve_members[Boolean] Should the smart group preserve it's current members?
    def set_static(*params)
      return unless @is_smart

      preserve_members = params.include? :preserve_members

      @is_smart = false

      clear() unless preserve_members
    end

    # How many members of the group?
    #
    # @return [Integer] the number of members of the group
    #
    def size
      @members.count
    end

    # @return [Array<String>] the names of the group members
    #
    def member_names
      @members.map { |m| m[:name] }
    end

    # @return [Array<Integer>] the ids of the group members
    #
    def member_ids
      @members.map { |m| m[:id] }
    end

    # Replace all @members with an array of uniq device identfiers (names, ids, serial numbers, etc)
    # E.g: [ 'lambic', 1233, '2341', 'monkey']
    #
    # They must all be in the JSS or an error is raised
    # before doing anything. See {#check_member}
    #
    # @param new_members[Array<Integer,String>] the new group members
    #
    # @return [void]
    #
    def members=(new_members)
      raise UnsupportedError, "Smart group members can't be changed." if @is_smart
      raise InvalidDataError, 'Arg must be an array of names and/or ids' unless new_members.is_a? Array
      ok_members = []
      new_members.each do |m|
        ok_members << check_member(m)
      end

      ok_members.uniq!

      # make sure we've actually changed...
      return if members.map { |m| m[:id] }.sort == ok_members.map { |m| m[:id] }.sort
      @members = ok_members
      @need_to_update = true
    end

    # Add a member, by name or id
    #
    # @param m[Integer,String] the id or name of the member to add
    #
    # @return [void]
    #
    def add_member(mem)
      raise UnsupportedError, "Smart group members can't be changed." if @is_smart
      @members << check_member(mem)
      @need_to_update = true
    end

    # Remove a member by id, or name
    #
    # @param m[Integer,String] the id or name of the member to remove
    #
    # @return [void]
    #
    def remove_member(mem)
      raise InvalidDataError, "Smart group members can't be changed." if @is_smart
      raise InvalidDataError, "Can't remove nil" if mem.nil?
      removed = @members.reject! { |mm| [mm[:id], mm[:name], mm[:username]].include? mem }
      @need_to_update = true if removed
    end

    # Remove all members
    #
    # @return [void]
    #
    def clear
      raise InvalidDataError, "Smart group members can't be changed." if @is_smart
      return if @members.empty?
      @members.clear
      @need_to_update = true
    end

    # Immediatly add and/or remove members in this static group
    #
    # IMPORTANT: This method changes the group in the JSS immediately,
    #   there is no need to call #update/#save
    #
    # @param add_members [String, Integer, Array<String, Integer>] valid
    #   identifier(s) for members to add
    #
    # @param remove_members [String, Integer, Array<String, Integer>] valid
    #   identifier(s) for members to remove
    #
    # @param api [JSS::APIConnection] The API connetion to use, uses the default
    #   connection if not specified
    #
    # @return [void]
    #
    def change_membership(add_members: [], remove_members: [])
      self.class.change_membership(@id, add_members: add_members, remove_members: remove_members, api: @api)
      refresh_members
    end

    # Refresh the membership from the API
    #
    # @return [Array<Hash>] the refresh membership
    #
    def refresh_members
      @members = @api.get_rsrc(@rest_rsrc)[self.class::RSRC_OBJECT_KEY][self.class::MEMBER_CLASS::RSRC_LIST_KEY]
    end

    # aliases

    alias smart? is_smart
    alias notify_on_change? notify_on_change
    alias notify? notify_on_change
    alias count size

    # Public Instance Methods
    #####################################
    private

    # Check that a potential group member is valid in the JSS.
    # Arg must be an id or name.
    # An exception is raised if the device doesn't exist.
    #
    # @return [Hash{:id=>Integer,:name=>String}] the valid id and name
    #
    def check_member(m)
      potential_members = self.class::MEMBER_CLASS.map_all_ids_to(:name, api: @api)
      if m.to_s =~ /^\d+$/
        return { id: m.to_i, name: potential_members[m] } if potential_members.key?(m.to_i)
      else
        return { name: m, id: potential_members.invert[m] } if potential_members.value?(m)
      end
      raise JSS::NoSuchItemError, "No #{self.class::MEMBER_CLASS::RSRC_OBJECT_KEY} matching '#{m}' in the JSS."
    end

    # the xml formated data for adding or updating this in the JSS,
    #
    def rest_xml
      doc = REXML::Document.new JSS::APIConnection::XML_HEADER
      group = doc.add_element self.class::RSRC_OBJECT_KEY.to_s
      group.add_element('name').text = @name
      group.add_element('is_smart').text = @is_smart
      if @is_smart
        group << @criteria.rest_xml if @criteria
        group.add_element('computers').text = nil
      else
        group << self.class::MEMBER_CLASS.xml_list(@members, :id)
      end

      add_site_to_xml(doc)

      doc.to_s
    end # rest_xml

  end # class ComputerGroup

end # module JSS

require 'jss/api_object/group/computer_group'
require 'jss/api_object/group/mobile_device_group'
require 'jss/api_object/group/user_group'
