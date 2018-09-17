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

require 'fileutils'

require_relative "common"

module Switch
  module Plugins
    class SwitchPreviousLink < Switch::Plugins::Common
      plugin_group :switch

      plugin_argument :destination_directory
      plugin_argument :application
      plugin_argument :version
      plugin_argument :switch_log

      plugin_argument :current_version, optional: true

      def self.description
        'switch application previous link'
      end

      def description
          "switching #{@destination_directory}/#{@application}/previous to current version"
      end

      def run
        self.puts 'remove previous link'
        if File.exist? "#{ @destination_directory }/#{ @application }/previous" or File.symlink? "#{ @destination_directory }/#{ @application }/previous"
          FileUtils.rm("#{ @destination_directory }/#{ @application }/previous") unless @dryrun
        else
          puts 'previous link doesn\'t exist.'
        end
        self.puts "create previous link with #{@current_version}"
        FileUtils.ln_s "#{ @destination_directory }/#{ @application }/releases/#{ @current_version }", "#{ @destination_directory }/#{ @application }/previous" unless @dryrun
      end

      def skip?
        @current_version.nil?
      end
    end
  end
end
