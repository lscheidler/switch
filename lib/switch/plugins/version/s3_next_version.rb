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

require 'aws-sdk-s3'

require_relative "../common"

module Switch
  module Plugins
    module Version
      class S3NextVersion < Switch::Plugins::Common
        attr_reader :version

        plugin_group :version
        plugin_setting :skip_auto_initialization, true

        plugin_argument :application
        plugin_argument :environment_name

        plugin_argument :access_key_id, optional: true
        plugin_argument :secret_access_key, optional: true
        plugin_argument :bucket_region, optional: true, default: 'eu-central-1'
        plugin_argument :bucket_name, optional: true
        plugin_argument :object_prefix, optional: true, default: 'versions/'

        def self.description
          'get next version from s3'
        end

        def after_initialize
          unless @bucket_name.nil?
            bucket = get_bucket
            list = get_list(bucket)
            @version = list.last[:version] unless list.empty?
          end
        end

        def get_bucket
          if @access_key_id and @secret_access_key
            Aws.config.update(
              credentials: Aws::Credentials.new(@access_key_id, @secret_access_key)
            )
          end

          s3 = Aws::S3::Resource.new(
            region: @bucket_region
          )
          s3.bucket(@bucket_name)
        end

        def get_list bucket
          result = []
          bucket.objects.each do |s3_object|
            next if s3_object.key.start_with? @object_prefix
            next if s3_object.key !~ /#{@environment_name}\/#{@application}/

            s3_object.key.match(/^([^\/]+)\/(.*)\/([^\/]+)$/)
            environment = $1
            app = $2
            version = File.basename($3, '.gpg') if not $3.nil?

            if environment and app and version
              row = {
                environment: environment,
                application: app,
                version: version,
                last_modified: s3_object.last_modified.to_s
              }
              result << row
            end
          end
          result
        end

        def skip?
          true
        end
      end
    end
  end
end
