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
      class CurrentDockerImageVersion < Switch::Plugins::Common
        attr_reader :version

        plugin_group :version
        plugin_setting :skip_auto_initialization, true

        plugin_argument :application
        plugin_argument :ecr_repository
        plugin_argument :environment_name

        def self.version_description
          'get current version'
        end

        def after_initialize
          cmd = ['docker', 'inspect', @ecr_repository + ':' + @application + '-' + @environment_name]
          @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: false, print_cmd: false)

          if @status.success?
            tags = JSON::parse(@status.stdout).first['RepoTags']
            tags.delete(@ecr_repository + ':' + @application + '-' + @environment_name)
            @version = tags.first[/#{@ecr_repository}:#{@application}-(.*)/, 1] unless tags.empty?
          end
        end

        def mtime
          cmd = ['docker', 'inspect', @ecr_repository + ':' + @application + '-' + @environment_name]
          @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: false, print_cmd: false)

          if @status.success?
            JSON::parse(@status.stdout).first['Created']
          end
        end

        def skip?
          true
        end
      end
    end
  end
end
