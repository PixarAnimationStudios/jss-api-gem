# Copyright 2018 Pixar

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

# The Module
module Jamf

  # Classes
  #####################################

  # A building defined in the JSS
  class Category < Jamf::CollectionResource

    # Mix-Ins
    #####################################

    include Jamf::ChangeLog
    include Jamf::Referable

    # Constants
    #####################################

    RSRC_VERSION = 'v2'.freeze

    RSRC_PATH = 'categories'.freeze

    # Object Model / Attributes
    # See APIObject class documentation for details
    # of how the OBJECT_MODEL hash works.
    #####################################
    OBJECT_MODEL = {

      # @!attribute [r] id
      #   @return [Integer]
      id: {
        class: :integer,
        identifier: :primary,
        readonly: true
      },

      # @!attribute name
      #   @return [String]
      name: {
        class: :string,
        identifier: true,
        validator: :non_empty_string,
        required: true
      },

      # @!attribute priority
      #   @return [Integer]
      priority: {
        class: :integer
      }
    }.freeze

    parse_object_model

  end # class

end # module