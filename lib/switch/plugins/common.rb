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

require 'execute'
require 'plugin'

module Switch
  module Plugins
    class Common < Plugin
      include Execute

      plugin_setting :disabled, true

      plugin_argument :dryrun, optional: true
      plugin_argument :output, optional: true

      def self.description
      end

      def description
        self.class.description
      end

      def puts msg
        @output.yield msg if @output
      end

      def skip?
        false
      end

      def self.show_always?
        false
      end
    end
  end
end
