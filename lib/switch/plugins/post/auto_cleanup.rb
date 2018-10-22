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
      class AutoCleanup < Switch::Plugins::Common
        plugin_group :post

        plugin_argument :destination_directory
        plugin_argument :application
        plugin_argument :version

        plugin_argument :keep_releases, optional: true, default: 5
        plugin_argument :switch_only, optional: true
        plugin_argument :auto_cleanup, optional: true, default: true

        def self.post_description
          'Cleanup old releases'
        end

        def post_description
          result = self.class.description + ":\n"
          result += get_auto_cleanup_candidates.map{|x| '      - ' + x}.join("\n")
          result
        end

        def post
          get_auto_cleanup_candidates.each do |version|
            self.puts "cleanup old release #{version}"
            execute(['sudo', '-n', '-u', 'app', 'switch-cleanup', "-a", @application, "-v", version], print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
          end
        end

        def get_auto_cleanup_candidates
          if not @auto_cleanup_canditates
            canditates = Dir.glob("#{ @destination_directory }/#{ @application }/releases/*").sort do |a,b|
              File.mtime(a) <=> File.mtime(b)
            end.map{|x| File.basename(x)}
            canditates.delete(@version)
            canditates.pop(@keep_releases)
            @auto_cleanup_canditates = canditates
          end
          @auto_cleanup_canditates
        end

        def skip?
          (not @auto_cleanup) or @switch_only or get_auto_cleanup_candidates.empty?
        end
      end
    end
  end
end
