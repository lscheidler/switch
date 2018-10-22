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
      class Cleanup < Switch::Plugins::Common
        plugin_group :post

        plugin_argument :current_version
        plugin_argument :destination_directory
        plugin_argument :application

        plugin_argument :switch_only, optional: true
        plugin_argument :cleanup, optional: true, default: false

        def self.post_description
          'remove old release'
        end

        def post
          if @current_version and File.directory? "#{ @destination_directory }/#{ @application }/releases/#{ @current_version }"
            self.puts 'cleanup old release'
            execute(['sudo', '-n', '-u', 'app', 'switch-cleanup', "-a", @application, "-v", @current_version], print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
          end
        end

        def skip?
          (not @cleanup) or @switch_only
        end
      end
    end
  end
end
