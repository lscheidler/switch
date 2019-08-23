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
      class DockerAutoCleanup < Switch::Plugins::Common
        plugin_group :post

        plugin_argument :application
        plugin_argument :ecr_repository
        plugin_argument :version

        plugin_argument :keep_releases, optional: true, default: 5
        plugin_argument :switch_only, optional: true
        plugin_argument :auto_cleanup, optional: true, default: true

        def self.post_description
          'Cleanup previous docker images'
        end

        def post_description
          result = self.class.post_description + ":\n"
          result += get_auto_cleanup_candidates.map{|x| '      - ' + x}.join("\n")
          result
        end

        def post
          get_auto_cleanup_candidates.each do |version|
            self.puts "cleanup old release #{version}"
            execute(['docker', 'rmi', @ecr_repository + ':' + version], print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
          end
        end

        def get_auto_cleanup_candidates
          if not @auto_cleanup_canditates
            images = execute(['docker', 'images', '-f', "reference=#{@ecr_repository}:#{@application}-[0-9]*", '--format', '{{.Tag}}'], print_lines: false, print_cmd: false, raise_exception: true)
            canditates = images.stdout_lines.sort
            canditates.delete(@application + '-' + @version)
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
