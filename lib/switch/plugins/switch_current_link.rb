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

require 'etc'
require 'fileutils'

require_relative "common"

module Switch
  module Plugins
    class SwitchCurrentLink < Switch::Plugins::Common
      plugin_group :switch

      plugin_argument :environment_name
      plugin_argument :destination_directory
      plugin_argument :application
      plugin_argument :version
      plugin_argument :switch_log

      plugin_argument :current_version, optional: true

      def self.switch_description
        'switch application current link'
      end

      def switch_description
          "switching #{@destination_directory}/#{@application}/current to new version"
      end

      def switch
        self.puts 'remove current link'
        if File.exist? "#{ @destination_directory }/#{ @application }/current" or File.symlink? "#{ @destination_directory }/#{ @application }/current"
          FileUtils.rm("#{ @destination_directory }/#{ @application }/current") unless @dryrun
        else
          puts 'current link doesn\'t exist.'
        end
        self.puts "create current link with #{@version}"
        FileUtils.ln_s "#{ @destination_directory }/#{ @application }/releases/#{ @version }", "#{ @destination_directory }/#{ @application }/current" unless @dryrun

        @switch_log.info "user=#{get_user} environment=#{@environment_name} application=#{@application} from=#{@current_version} to=#{@version}"
      end

      def get_user
        @user ||= Etc.getlogin
      end
    end
  end
end
