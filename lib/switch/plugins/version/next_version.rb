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
      class NextVersion < Switch::Plugins::Common
        plugin_group :version
        plugin_setting :skip_auto_initialization, true

        plugin_argument :environment_name
        plugin_argument :destination_directory
        plugin_argument :application
        plugin_argument :version

        plugin_argument :artifact_plugin, optional: true, default: 'Switch::Plugins::Artifact::GetArtifact'
        plugin_argument :extensions, optional: true, default: ['jar', 'war']
        plugin_argument :force, optional: true

        def self.version_description
          'get next version'
        end

        def after_initialize
          destination_directory = "#{ @destination_directory }/#{ @application }/releases/#{ @version }"

          if not File.exist? destination_directory or Dir.glob("#{destination_directory}/*").empty? or @force
            PluginManager.instance[@artifact_plugin].new(destination_directory: @destination_directory, environment_name: @environment_name, application: @application, version: @version, dryrun: @dryrun, force: @force)
          end
        end

        def mtime
          @mtime = File.stat(Dir.glob("#{ @destination_directory }/#{ @application }/releases/#{@version}/*.{#{@extensions.join(',')}}").first).mtime
          @mtime
        end

        def skip?
          true
        end
      end
    end
  end
end
