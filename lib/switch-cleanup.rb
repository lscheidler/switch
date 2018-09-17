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

require 'output_helper'
require 'overlay_config'

require "switch/version"

module Switch
  # command line interface
  class CleanupCLI

    def initialize
      set_defaults
      parse_arguments

      must_set 'application', @config[:application]
      must_set 'version', @config[:version]

      run
    end

    # set defaults
    def set_defaults
      OutputHelper::Message.config subsection_prefix: "| #{File.basename $0} >"

      @config = OverlayConfig::Config.new(
        config_scope: 'switch',
        defaults: {
          base_directory: '/data/app',
          debug: false,
          output: Proc.new {|msg| Kernel.subsection msg, color: :yellow}
        }
      )
      @config[:destination_directory] = @config.get(:base_directory) + '/data'
    end

    # parse command line arguments
    def parse_arguments
      @command_line_options = {}
      @config.insert 0, '<command_line>', @command_line_options

      @options = OptionParser.new do |opts|
        opts.on('-a', '--application STRING', 'set application name') do |application|
          @command_line_options[:application] = application
        end

        opts.on('-d', '--destination DIR', 'set destination directory', "default: #{@config[:destination_directory]}") do |directory|
          @command_line_options[:destination_directory] = directory
        end

        opts.on('-n', '--dryrun', 'do not switch') do
          @command_line_options[:dryrun] = true
        end

        opts.on('-V', '--version STRING', 'set application version to deploy') do |version|
          @command_line_options[:version] = version
        end
      end
      @options.parse!
    end

    def must_set var_name, var
      if (var.is_a? Symbol and not instance_variable_defined? "@#{var}") or var.nil?
        subsection "Argument --#{var_name} must be set.", color: :red
        exit 1
      end
    end

    def run
      application_directory = @config[:destination_directory] + '/' + @config[:application]
      version_directory =  application_directory + '/releases/' + @config[:version]

      # check, if destination is directory
      if not File.directory? version_directory
        subsection 'No such directory ' + version_directory, color: :red
        exit 1
      end

      # check, if version is linked as current
      if File.exist? application_directory + '/current' and File.readlink application_directory + '/current'
        subsection 'Version is currently active, abort. (' + version_directory + ')'
        exit 1
      end

      subsection "Deleting #{@config[:application]}@#{@config[:version]} (#{version_directory})", color: :yellow
      FileUtils.rm_rf version_directory unless @config[:dryrun]
    end
  end
end
