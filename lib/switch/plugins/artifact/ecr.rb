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

require 'aws-sdk-ecr'
require 'base64'
require 'json'

module Switch
  module Plugins
    module Artifact
      class ECR < Switch::Plugins::Common
        plugin_group :artifact
        plugin_setting :skip_auto_initialization, true

        plugin_argument :ecr_repository
        plugin_argument :application
        plugin_argument :version

        plugin_argument :access_key_id, optional: true
        plugin_argument :secret_access_key, optional: true
        plugin_argument :aws_region, optional: true, default: 'eu-central-1'

        def self.artifact_description
          'get artifact'
        end

        def after_initialize
          login

          cmd = ['docker', 'pull', @ecr_repository + ':' + @application + '-' + @version]
          @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: true, print_cmd: true, raise_exception: true, dryrun: @dryrun)
          fail "docker pull failed." if not @status.success?
        end

        def login
          if @access_key_id and @secret_access_key
            Aws.config.update(
              credentials: Aws::Credentials.new(@access_key_id, @secret_access_key)
            )
          end

          ecr = Aws::ECR::Resource.new(
            region: @aws_region
          )
          authorization_token_resource = ecr.client.get_authorization_token
          username, token = Base64.decode64(authorization_token_resource.authorization_data.first.authorization_token).split(':')
          cmd = ['docker', 'login', '-u', username, '-p', token, authorization_token_resource['authorization_data'].first['proxy_endpoint']]

          subsection 'docker login', color: :yellow
          @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: true, print_cmd: false, raise_exception: true, dryrun: @dryrun)
          fail "docker login failed." if not @status.success?
        end

        def mtime
          cmd = ['docker', 'inspect', @ecr_repository + ':' + @application + '-' + @version]
          @status = execute(cmd, io_options: {:err=>[:child, :out]}, print_lines: false, print_cmd: false, raise_exception: true)

          JSON::parse(@status.stdout).first['Created']
        end

        def skip?
          true
        end
      end
    end
  end
end
