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
    module Pre
      class StopProcess < Switch::Plugins::Common
        plugin_group :pre

        plugin_argument :application

        plugin_argument :switch_only, optional: true

        def self.pre_description
          'stopping process'
        end

        def pre
          execute(['sudo', '-n', 'systemctl', 'stop', @application.gsub('/', '-')], print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
        end

        def skip?
          @switch_only
        end
      end
    end
  end
end
