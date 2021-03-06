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
    module Post
      class DockerCleanup < Switch::Plugins::Common
        plugin_group :post

        plugin_argument :current_version
        plugin_argument :ecr_repository
        plugin_argument :environment_name
        plugin_argument :application

        plugin_argument :switch_only, optional: true
        plugin_argument :cleanup, optional: true, default: false

        def self.post_description
          'remove previous docker image'
        end

        def post
          execute(
                  [
                    'docker',
                    'rmi', 
                    @ecr_repository + ':' + @application + '-' + @current_version,
                    @ecr_repository + ':' + @application + '-' + @environment_name + '-previous'
                  ], print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun
                 )
        end

        def skip?
          (not @cleanup) or @switch_only
        end
      end
    end
  end
end
