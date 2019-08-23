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

require_relative "common"

module Switch
  module Plugins
    class DockerTagAndPush < Switch::Plugins::Common
      plugin_group :switch

      plugin_argument :application
      plugin_argument :ecr_repository
      plugin_argument :environment_name
      plugin_argument :switch_log
      plugin_argument :version

      plugin_argument :current_version, optional: true

      def self.switch_description
        'docker tag and push'
      end

      def switch_description
        [
          "tag and push new docker image #{@application}-#{@version} to #{@application}-#{@environment_name}",
          "tag and push previous docker image #{@application}-#{@current_version} to #{@application}-#{@environment_name}-previous"
        ]
      end

      def switch
        self.puts "tag new docker image #{@application}-#{@version} to #{@application}-#{@environment_name}"
        cmd = ['docker', 'tag', @ecr_repository + ':' + @application + '-' + @version, @ecr_repository + ':' + @application + '-' + @environment_name]
        @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
        fail "docker tag failed." if not @status.success?

        self.puts "push tag #{@application}-#{@environment_name}"
        cmd = ['docker', 'push', @ecr_repository + ':' + @application + '-' + @environment_name]
        @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
        fail "docker tag failed." if not @status.success?

        @switch_log.info "user=#{get_user} environment=#{@environment_name} application=#{@application} from=#{@current_version} to=#{@version}"

        self.puts "tag previous docker image #{@application}-#{@current_version} to #{@application}-#{@environment_name}-previous"
        cmd = ['docker', 'tag', @ecr_repository + ':' + @application + '-' + @current_version, @ecr_repository + ':' + @application + '-' + @environment_name + '-previous']
        @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
        fail "docker tag failed." if not @status.success?

        self.puts "push tag #{@application}-#{@environment_name}-previous"
        cmd = ['docker', 'push', @ecr_repository + ':' + @application + '-' + @environment_name + '-previous']
        @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
        fail "docker tag failed." if not @status.success?
      end

      def get_user
        @user ||= Etc.getlogin
      end
    end
  end
end
