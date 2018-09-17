# Copyright 2018 Lars Eric Scheidler
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "../common"

module Switch
  module Plugins
    module Version
      class CurrentVersion < Switch::Plugins::Common
        attr_reader :version

        plugin_group :version
        plugin_setting :skip_auto_initialization, true

        plugin_argument :destination_directory
        plugin_argument :application

        plugin_argument :extensions, optional: true, default: ['jar', 'war']

        def self.description
          'get current version'
        end

        def after_initialize
          if File.exist? "#{ @destination_directory }/#{ @application }/current"
            @version = File.basename(File.readlink("#{ @destination_directory }/#{ @application }/current"))
          end
        end

        def mtime
          @mtime = File.stat(Dir.glob("#{ @destination_directory }/#{ @application }/current/*.{#{@extensions.join(',')}}").first).mtime unless @version.nil?
          @mtime
        end

        def skip?
          true
        end
      end
    end
  end
end
