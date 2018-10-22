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
    module Artifact
      class GetArtifact < Switch::Plugins::Common
        plugin_group :artifact
        plugin_setting :skip_auto_initialization, true

        plugin_argument :environment_name
        plugin_argument :destination_directory
        plugin_argument :application
        plugin_argument :version

        plugin_argument :force, optional: true

        def self.artifact_description
          'get artifact'
        end

        def after_initialize
          cmd = ['sudo', '-n', 'artifact', '--get', '-a', @application, '-e', @environment_name, '-v', @version, '-d', @destination_directory]
          cmd << '-f' if @force

          @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
          fail "retrieval of #{@environment_name}/#{@application}/#{@version} failed." if not @status.success?
        end

        def skip?
          true
        end
      end
    end
  end
end
