### Copyright 2019 Pixar

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

module JSS
    
    # Module for containing the different types of DirectoryBindings stored within the JSS
    
    module DirectoryBindingType

        # Module Variables
        #####################################

        # Module Methods
        #####################################

        # Classes
        #####################################

        # Class for the specific ADmitMac DirectoryBinding type stored within the JSS
        # 
        # @author Tyler Morgan
        #
        # @note "Map Home Directory To Attribute" is currently only available in the Jamf Pro UI not through the API.
        #
        # Attributes
        # @!attribute [rw] require_confirmation
        # @!attribute [rw] local_home
        # @!attribute [rw] mount_style
        # @!attribute [rw] default_shell
        # @!attribute [rw] mount_network_home
        # @!attribute [rw] place_home_folders
        # @!attribute [rw] uid
        # @!attribute [rw] user_gid
        # @!attribute [rw] gid
        # @!attribute [rw] admin_group
        # @!attribute [rw] cached_credentials
        # @!attribute [rw] add_user_to_local
        # @!attribute [rw] users_ou
        # @!attribute [rw] groups_ou
        # @!attribute [rw] printers_ou
        # @!attribute [rw] shared_folders_ou
        # TODO: Include default values upon creation

        class ADmitMac < DirectoryBindingType
            # Mix-Ins
            #####################################

            # Class Methods
            #####################################

            # Class Constants
            #####################################

            # Attributes
            #####################################

            # @return [Boolean] Require confirmation before creating the account locally
            attr_reader :require_confirmation

            # @return [String] The path to the local home directory
            attr_reader :local_home

            # @return [Symbol] The mount style for the home directory
            attr_reader :mount_style

            # @return [String] The default shell to be used by the user
            attr_reader :default_shell

            # @return [Boolean] Mount the network home share locally
            attr_reader :mount_network_home

            # @return [String] The path the user's home folder(s) would be created in
            attr_reader :place_home_folders

            # @return [String] The UID to be mapped to the user
            attr_reader :uid

            # @return [String] The User's Group ID to be mapped to the user
            attr_reader :user_gid
            
            # @return [String] The Group ID to be mapped
            attr_reader :gid

            # @return [Array<String>] The groups to be given admin rights upon logging in
            attr_reader :admin_groups

            # @return [Boolean] Cache credentials for authentication off network
            attr_reader :cached_credentials

            # @return [Boolean] Add the user as a local account
            attr_reader :add_user_to_local

            # @return [String] The OU path for the user
            attr_reader :users_ou

            # @return [String] The OU path for the group
            attr_reader :groups_ou

            # @return [String] The OU path for the printers
            attr_reader :printers_ou

            # @return [String] The OU path for the shared folders
            attr_reader :shared_folders_ou

            # Constructor
            #####################################

            # An initializer for the ADmitMac object.
            # 
            # @author Tyler Morgan
            # @see JSS::DirectoryBinding
            # @see JSS::DirectoryBindingType
            #
            # @note Due to a JSS API funk, mount_style is not able to be configured through the API. It is linked to place_home_folders
            #
            # @param [Hash] initialize data
            def initialize(init_data)

                # Return without processing anything since there is
                # nothing to process.
                return if init_data.nil?

                # Process the provided information
                @require_confirmation = init_data[:require_confirmation]
                @default_shell = init_data[:default_shell]
                @mount_network_home = init_data[:mount_network_home]
                @place_home_folders = init_data[:place_home_folders]
                @uid = init_data[:uid]
                @user_gid = init_data[:user_gid]
                @gid = init_data[:gid]
                @cached_credentials = init_data[:cached_credentials]
                @add_user_to_local = init_data[:add_user_to_local]
                @users_ou = init_data[:users_ou]
                @groups_ou = init_data[:groups_ou]
                @printers_ou = init_data[:printers_ou]
                @shared_folders_ou = init_data[:shared_folders_ou]
                @mount_style = init_data[:mount_style]

                if init_data[:local_home].nil? || init_data[:local_home].is_a?(String)
                    raise JSS::InvalidDataError, "Local Home must be one of #{HOME_FOLDER_TYPE.values.join(', ')}." unless HOME_FOLDER_TYPE.values.include? init_data[:local_home] || init_data[:local_home].nil?

                    @local_home = init_data[:local_home]
                else
                    raise JSS::InvalidDataError, "Local Home must be one of :#{HOME_FOLDER_TYPE.keys.join(',:')}." unless HOME_FOLDER_TYPE.keys.include? init_data[:local_home]
                end

                if init_data[:admin_group].nil?
                    # This is needed since we have the ability to add and
                    # remove admin groups from this array.
                    @admin_group = []
                elsif init_data[:admin_group].is_a? String
                    @admin_group = init_data[:admin_group].split(',')
                else
                    @admin_group = init_data[:admin_group]
                end
            end

                

            # Public Instance Methods
            #####################################

            # Require confirmation before creating a mobile account on the system.
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [Bool]
            #
            # @raise [JSS::InvalidDataError] If the new value doesn't match a Bool value
            #
            # @return [void]
            def require_confirmation=(newvalue)

                raise JSS::InvalidDataError, "require_confirmation must be true or false." unless newvalue.is_a? Bool

                @require_confirmation = newvalue
                
                self.container&.should_update
            end


            # The type of home directory type created upon logging into a system
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [Symbol] The key specific to the folder type you want in HOME_FOLDER_TYPE
            # @see JSS::DirectoryBindingType::HOME_FOLDER_TYPE
            #
            # @raise [JSS::InvalidDataError] If the new value is not one of the possible keys in HOME_FOLDER_TYPE
            #
            # @return [void]
            def local_home=(newvalue)
                
                raise JSS::InvalidDataError, "local_home must be one of :#{HOME_FOLDER_TYPE.keys.join(',:')}." unless HOME_FOLDER_TYPE.keys.include? newvalue

                @local_home = HOME_FOLDER_TYPE[newvalue]
                
                self.container&.should_update
            end

            # The default shell assigned first upon logging into a system
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The string path of the shell file being set as the default
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def default_shell=(newvalue)

                raise JSS::InvalidDataError, "default_shell must be empty or a string." unless newvalue.is_a?(String)

                @default_shell = newvalue
                
                self.container&.should_update
            end


            # Mount network home folder on desktop
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [Bool]
            #
            # @raise [JSS::InvalidDataError] If the new value is not a Bool
            #
            # @return [void]
            def mount_network_home=(newvalue)

                raise JSS::InvalidDataError, "mount_network_home must be true or false." unless newvalue.is_a? Bool

                @mount_network_home = newvalue
                
                self.container&.should_update
            end

            # Path at which home folders are placed
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The string path of the folder which user's directory files and folders will be created
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def place_home_folders=(newvalue)

                raise JSS::InvalidDataError, "place_home_folders must be a string." unless newvalue.is_a? String

                @place_home_folders = newvalue
                
                self.container&.should_update
            end

            # Jamf has these linked for some reason...
            alias mount_style place_home_folders


            # Map specific UID to Attribute
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The UID you want to be mapped
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def uid=(newvalue)

                raise JSS::InvalidDataError, "uid must be a string, integer, or nil." unless newvalue.is_a?(String) || newvalue.is_a?(Integer) || newvalue.nil?

                @uid = newvalue
                
                self.container&.should_update
            end

            
            # Map specific a User's GID to Attribute
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The User's GID you want to be mapped
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def user_gid=(newvalue)

                raise JSS::InvalidDataError, "user_gid must be a string, integer, or nil." unless newvalue.is_a?(String) || newvalue.is_a?(Integer) || newvalue.nil?

                @user_gid = newvalue
                
                self.container&.should_update
            end


            # Map specific GID to Attribute
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The GID you want to be mapped
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def gid=(newvalue)

                raise JSS::InvalidDataError, "gid must be a string, integer, or nil." unless newvalue.is_a?(String) || newvalue.is_a?(Integer) || newvalue.nil?

                @gid = newvalue
                
                self.container&.should_update
            end

            # Set specific groups to become administrators to a system.
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [Array<String>] An array of all the admin group names you want to set.
            # @see add_admin_group
            # @see remove_admin_group
            #
            # @raise [JSS::InvalidDataError] If the new value is not an Array
            #
            # @return [void]
            def admin_groups=(newvalue)
                
                raise JSS::InvalidDataError, "An Array must be provided, please use add_admin_group and remove_admin_group for individual group additions and removals." unless newvalue.is_a? Array

                @admin_group = newvalue
                
                self.container&.should_update
            end


            # The number of times a user can log into the device while not connected to a network
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [Integer] The number of times you want a user to login while not connected to a network
            #
            # @raise [JSS::InvalidDataError] If the new value is not an Integer
            #
            # @return [void]
            def cached_credentials=(newvalue)

                raise JSS::InvalidDataError, "cached_credentials must be an integer." unless newvalue.is_a? Integer

                @cached_credentials = newvalue
                
                self.container&.should_update
            end


            # If the user is a member of one of the groups in admin_group, add them
            # to the local administrator group.
            # 
            # @author Tyler Morgan
            # @see admin_group
            #
            # @param newvalue [Bool]
            #
            # @raise [JSS::InvalidDataError] If the new value is not a Bool
            #
            # @return [void]
            def add_user_to_local=(newvalue)

                raise JSS::InvalidDataError, "add_user_to_local must be true or false." unless newvalue.is_a? Bool

                @add_user_to_local = newvalue
                
                self.container&.should_update
            end


            # An OU path for specific Users
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The OU path for the specific user
            # @note Not sure what this is used for
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def users_ou=(newvalue)

                raise JSS::InvalidDataError, "users_ou must be either a string or nil." unless newvalue.is_a? String || newvalue.nil?

                @users_ou = newvalue
                
                self.container&.should_update
            end


            # An OU path for specific User Groups
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The OU path for the specific user group
            # @note Not sure what this is used for
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def groups_ou=(newvalue)

                raise JSS::InvalidDataError, "groups_ou must be either a string or nil." unless newvalue.is_a? String || newvalue.nil?

                @groups_ou = newvalue
                
                self.container&.should_update
            end


            # An OU path for specific Printers
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The OU path for the specific printer
            # @note Not sure what this is used for
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def printers_ou=(newvalue)

                raise JSS::InvalidDataError, "printers_ou must be either a string or nil." unless newvalue.is_a? String || newvalue.nil?

                @printers_ou = newvalue
                
                self.container&.should_update
            end


            # An OU path for specific shared folders
            # 
            # @author Tyler Morgan
            #
            # @param newvalue [String] The OU path for the specific shared folders
            # @note Not sure what this is used for
            #
            # @raise [JSS::InvalidDataError] If the new value is not a String
            #
            # @return [void]
            def shared_folders_ou=(newvalue)

                raise JSS::InvalidDataError, "shared_folders_ou must be either a string or nil." unless newvalue.is_a? String || newvalue.nil?

                @shared_folders_ou = newvalue
                
                self.container&.should_update
            end

            
            # An a specific admin group to admin_group
            # 
            # @author Tyler Morgan
            #
            # @param value [String] The admin group name you wish to add to the admin group list
            #
            # @raise [JSS::InvalidDataError] If the value provided is not a String
            # @raise [JSS::InvalidDataError] If the group provided is already a member of the admin_group array
            #
            # @return [Array <String>] An array of all the admin groups currently set.
            def add_admin_group(value)

                raise JSS::InvalidDataError, "Admin group must be a string." unless value.is_a? String
                raise JSS::InvalidDataError, "Admin group \"#{value}\" already is in the list of admin groups." unless !@admin_group.include? value

                @admin_group << value
                
                self.container&.should_update

                return @admin_group
            end


            # Remove a specific admin group to admin_group
            # 
            # @author Tyler Morgan
            #
            # @param value [String] The admin group name you wish to remove from the admin group list
            #
            # @raise [JSS::InvalidDataError] If the value provided is not a String
            # @raise [JSS::InvalidDataError] If the group provided is not in the admin_group array
            #
            # @return [Array <String>] An array of all the admin groups currently set.
            def remove_admin_group(value)

                raise JSS::InvalidDataError, "Admin group being removed must be a string" unless value.is_a? String
                raise JSS::InvalidDataError, "Admin group #{value} is not in the current admin group(s)." unless @admin_group.include? value

                @admin_group.delete value

                self.container&.should_update

                return @admin_group
            end


            # Return a REXML Element containing the current state of the DirectoryBindingType
            # object for adding into the XML of the container.
            # 
            # @author Tyler Morgan
            #
            # @return [REXML::Element]
            def type_setting_xml
                type_setting = REXML::Element.new "admitmac"
                type_setting.add_element("require_confirmation").text = @require_confirmation
                type_setting.add_element("local_home").text = @local_home
                type_setting.add_element("mount_style").text = @mount_style.downcase
                type_setting.add_element("default_shell").text = @default_shell
                type_setting.add_element("mount_network_home").text = @mount_network_home
                type_setting.add_element("place_home_folders").text = @place_home_folders
                type_setting.add_element("uid").text = @uid
                type_setting.add_element("user_gid").text = @user_gid
                type_setting.add_element("gid").text = @gid
                type_setting.add_element("add_user_to_local").text = @add_user_to_local
                type_setting.add_element("cached_credentials").text = @cached_credentials
                type_setting.add_element("users_ou").text = @users_ou
                type_setting.add_element("groups_ou").text = @groups_ou
                type_setting.add_element("printers_ou").text = @printers_ou
                type_setting.add_element("shared_folders_ou").text = @shared_folders_ou
                type_setting.add_element("admin_group").text = @admin_group.join(',').to_s unless @admin_group.nil?

                return type_setting
            end
        end

    end

end