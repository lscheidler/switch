# Copyright 2020 Lars Eric Scheidler
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

require "bundler/setup"

require 'highline/import'

require "switch/version"

require 'execute'
require 'plugin_manager'
require 'output_helper'
require 'overlay_config'

require 'switch/plugins'

module Switch
  # command line interface
  class CLI
    include Execute

    PLUGIN_TYPES = [
      'pre',
      'switch',
      'post',
      'notification'
    ]

    def initialize
      set_defaults
      parse_arguments

      must_set 'application', @config[:application]

      initialize_logfile

      run
    end

    # set defaults
    def set_defaults
      @script_name = File.basename($0)
      @config = OverlayConfig::Config.new(
        config_scope: 'switch',
        defaults: {
          action: :switch,
          auto_cleanup: true,
          base_directory: '/data/app',
          bucket_name: 'my-application-artifacts',
          current_version_plugin: 'Switch::Plugins::Version::CurrentVersion',
          debug: false,
          environment_name: '',
          keep_releases: 5,
          mode: 'default',
          next_version_plugin: 'Switch::Plugins::Artifact::Artifact',
          next_version_remote_plugin: 'Switch::Plugins::Version::S3NextVersion',
          relative_link: true,
          output: Proc.new {|msg| Kernel.subsection msg, color: :yellow},
          default_mode: {
            plugins: {
              "switch": [
                'SwitchPreviousLink',
                'SwitchCurrentLink'
              ],
              "post::before": [
                "UploadVersionInformation"
              ],
              "post::after": [
                "AutoCleanup",
                "Cleanup"
              ],
              "notification": [
                "Graphite"
              ]
            }
          }
        }
      )
      @config[:destination_directory] = @config.get(:base_directory) + '/data'
      @config[:modes]['default'] ||= @config.default_mode

      @switch_log_filename = @config.get(:base_directory) + '/logs/switch.log'

      @pm = PluginManager.instance

      begin
        require 'colorize'
        @use_colorize = true
      rescue LoadError
      end
    end

    # parse command line arguments
    def parse_arguments
      @command_line_options = {}
      @config.insert 0, '<command_line>', @command_line_options

      @options = OptionParser.new do |opts|
        opts.on('-a', '--application STRING', 'set application name') do |application|
          @command_line_options[:application] = application
        end

        opts.on('-c', '--cleanup', 'remove previous release', 'works only on staging with autoswitch at the moment') do
          @command_line_options[:cleanup] = true
        end

        opts.on('-f', '--force', 'force redeployment of version') do
          @command_line_options[:force] = true
        end

        opts.on('-d', '--destination DIR', 'set destination directory', "default: #{@config[:destination_directory]}") do |directory|
          @command_line_options[:destination_directory] = directory
        end

        opts.on('-e', '--environment-name ENV', 'set environment name', "default: #{@config.get(:environment_name)}") do |environment_name|
          @command_line_options[:environment_name] = environment_name
        end

        opts.on('-i', '--info', 'return version information as json') do
          @command_line_options[:action] = :info
        end

        opts.on('-k', '--keep-releases NUM', Integer, 'number of releases, which are not affected from auto cleanup, youngest first', "default: #{@config[:keep_releases]}") do |keep_releases|
          @command_line_options[:keep_releases] = keep_releases
        end

        opts.on('-m', '--deploy-mode MODE', 'set deployment mode', "default: #{@config[:mode]}") do |mode|
          @command_line_options[:mode] = mode
        end

        opts.on('-n', '--dryrun', 'do not switch') do
          @command_line_options[:dryrun] = true
        end

        opts.on('--no-auto-cleanup', 'do not cleanup old releases', "default: #{@config[:auto_cleanup]}") do
          @command_line_options[:auto_cleanup] = false
        end

        opts.on('--prefetch', 'prefetch artifact') do
          @command_line_options[:action] = :prefetch
        end

        opts.on('--switch-only', 'do not run any additional hooks') do
          @command_line_options[:switch_only] = true
        end

        opts.on('-t', '--type NAME', 'set type of application (cron, tomcat, service)') do |type|
          @command_line_options[:type] = type.to_sym
        end

        opts.on('-V', '--version STRING', 'set application version to deploy') do |version|
          @command_line_options[:version] = version
        end

        opts.on('-y', '--assume-yes', 'switch automaticly without interaction') do
          @assume_yes = true
        end

        ## EXAMPLES
        opts.separator "
EXAMPLES:

    # switching application staging/tools/mailconsumer to 1.0.1
    #{@script_name} --application tools/mailconsumer --version 1.0.1
"
      end
      @options.parse!
    end

    def must_set var_name, var
      if (var.is_a? Symbol and not instance_variable_defined? "@#{var}") or var.nil?
        warn colorize("| Argument --#{var_name} must be set.", color: :red)
        exit 1
      end
    end

    def initialize_logfile
      @switch_log = Logger.new @switch_log_filename
      @config[:switch_log] = @switch_log

      @log = Logger.new STDOUT
      @log.level = (@config[:debug]) ? Logger::DEBUG : Logger::INFO
    end

    def run
      @application_service_name = @config[:application].gsub('/', '-')

      @pm.log = @log

      @config.load_config_file_at 1, "/etc/default/#{@config.application}.switch.json" if File.exist? "/etc/default/#{@config.application}.switch.json"
      get_application_type unless @config[:type]
      @config.insert 1, "<type_#{@config.type.to_s}>", @config.types.get(@config.type.to_s, default: {})
      @config.insert 2, "<mode_#{@config.mode.to_s}>", @config.modes.get(@config.mode.to_s, default: {})

      get_current_version

      case @config.action
      when :info
        puts JSON::dump({
          currentVersion: @config[:current_version],
          currentVersionMtime: @config[:current_version_mtime],
        })
      when :prefetch
        get_next_version
      else
        get_next_version

        activate_plugins

        @pm.initialize_plugins(defaults: @config)

        if switch?
          each_plugin(PLUGIN_TYPES) do |plugin_group, plugin_class, plugin|
            if not plugin.nil? and not plugin.skip?
              plugin.send(plugin_group.to_s)
            end
          end
        end
      end
    end

    def get_current_version
      current_version = @pm[@config.get('current_version_plugin')].new(@config)
      @config[:current_version] = current_version.version

      begin
        @config[:current_version_mtime] = current_version.mtime
      rescue TypeError
        warn colorize('| failed to get modification time for release', color: :yellow)
      end
    end

    def get_next_version
      if @config[:version].nil?
        begin
          @config[:version] = @pm[@config.get('next_version_remote_plugin')].new(@config).version
        rescue
          warn colorize('| Retrieving remote version failed.', color: :yellow)
        end
      end

      must_set 'version', @config[:version]

      next_version = @pm[@config.get('next_version_plugin')].new(@config)

      begin
        @config[:version_mtime] = next_version.mtime
      rescue TypeError
        warn colorize('| failed to get modification time for release', color: :yellow)
      end
    end

    def get_application_type
      if not @config.get(:types).nil?
        @config.get(:types).each do |type, data|
          if data['pattern'] and @config[:application] =~ /#{data['pattern']}/
            @config[:type] = type.to_sym
          end
        end
      else
        warn colorize('| no application types set in switch config', color: :yellow)
      end

      if @config[:type].nil?
        if File.exist? '/usr/local/bin/'+@application_service_name
          st = execute(['/usr/local/bin/'+@application_service_name, '-i', 'TYPE'])
          if st.success?
            @config[:type] = st.stdout.strip.to_sym
          end
        else
          @config[:type] = :batch
        end
      end
    end

    def activate_plugins
      types = @config.get(:types)
      types ||= {} # if types is not set

      @plugins = {}
      PLUGIN_TYPES.map do |p|
        # before
        @plugins[p.to_s + '::before'] = @config.plugins.get(p.to_s + '::before')
        @plugins[p.to_s + '::before'] ||= @config.modes.get([@config.mode,'plugins'],{}).get(p.to_s + '::before', default: [])

        @plugins[p.to_s] = @config.plugins.get(p.to_s)
        @plugins[p.to_s] ||= @config.modes.get([@config.mode,'plugins'],{}).get(p.to_s, default: [])

        # after
        @plugins[p.to_s + '::after'] = @config.plugins.get(p.to_s + '::after')
        @plugins[p.to_s + '::after'] ||= @config.modes.get([@config.mode,'plugins'],{}).get(p.to_s + '::after', default: [])
      end

      plugin_not_found = false
      @plugins.each do |key, list_of_plugins|
        prefix = 'Switch::Plugins::'
        if key != :switch and not key.start_with? 'switch'
          prefix += key[/([^:]*)/, 1].to_s.capitalize + '::'
        end

        list_of_plugins.map! do |plugin|
          plugin_name = if plugin.start_with? '::'
                          'Switch::Plugins' + plugin
                        else
                          prefix + plugin
                        end
          @pm[plugin_name] and @pm[plugin_name].plugin_setting :disabled, false
          if @pm[plugin_name].nil?
            warn colorize('| cannot find plugin ' + plugin_name, color: :yellow)
            plugin_not_found = true
          end
          @pm[plugin_name]
        end
        exit 1 if plugin_not_found
      end
    end

    def switch?
      section "  switching #{colorize(@config[:application], color: :yellow)}", color: :yellow
      puts "    from:   #{colorize(@config[:current_version], color: :yellow)}#{( @config[:current_version_mtime].nil? ) ? "" : " 	(#{@config[:current_version_mtime]})"}"
      puts "    to:     #{colorize(@config[:version], color: :yellow)}#{( @config[:version_mtime].nil? ) ? "" : " 	(#{@config[:version_mtime]})"}"
      puts
      puts colorize('  Following commands are going to be executed:')

      each_plugin(PLUGIN_TYPES) do |plugin_group, plugin_class, plugin|
        if (plugin.nil? and plugin_class.show_always?) or (plugin and plugin_class.show_always? and plugin.skip?)
          puts colorize('    - skipping: ' + plugin_class.send((plugin_group.to_s + '_description').to_sym), color: :yellow)
        elsif not plugin.nil? and not plugin.skip?
          description = plugin.send((plugin_group.to_s + '_description').to_sym)
          if description.is_a? Array
            puts '    - ' + description.join("\n    - ")
          else
            puts '    - ' + description
          end
        end
      end
      puts

      begin
        @assume_yes or (ask(colorize('please enter \'ok\' to process (strg+c for exit): ', color: :red)) == 'ok')
      rescue Interrupt
        puts
      end
    end

    def each_plugin groups
      groups.each do |plugin_group|
        # before
        @plugins[plugin_group + '::before'].each do |plugin_class|
          yield plugin_group, plugin_class, @pm.instance(plugin_class.name)
        end

        #
        @plugins[plugin_group].each do |plugin_class|
          yield plugin_group, plugin_class, @pm.instance(plugin_class.name)
        end

        # after
        @plugins[plugin_group + '::after'].each do |plugin_class|
          yield plugin_group, plugin_class, @pm.instance(plugin_class.name)
        end
      end
    end

    def colorize line, color: :green
      if @use_colorize and line
        line.colorize(color)
      else
        line
      end
    end
  end
end
