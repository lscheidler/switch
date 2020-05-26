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

require 'aws-sdk-elasticloadbalancingv2'
require 'open-uri'

require_relative "common"

module Switch
  module Plugins
    class AwsALB < Switch::Plugins::Common
      plugin_group :pre
      plugin_group :post

      plugin_argument :application
      plugin_argument :aws_region, optional: true, default: 'eu-central-1'
      plugin_argument :alb_target_group, optional: true
      plugin_argument :access_key_id, optional: true
      plugin_argument :secret_access_key, optional: true

      plugin_argument :switch_only, optional: true

      def after_initialize
        begin
          @instance_id = open('http://169.254.169.254/latest/meta-data/instance-id', open_timeout: 1).read
        rescue Net::OpenTimeout
        end
        if @alb_target_group and @instance_id
          if @access_key_id and @secret_access_key
            Aws.config.update(
              credentials: Aws::Credentials.new(@access_key_id, @secret_access_key)
            )
          end

          @client = Aws::ElasticLoadBalancingV2::Resource.new(
            region: @aws_region
          ).client
        end
        # TODO if target_group has only one healthy target, skip?
      end

      def self.pre_description
        'deregister instance from loadbalancer'
      end

      def pre
        self.puts "deregister #{@instance_id} from #{@alb_target_group}"
        @client.deregister_targets({
          target_group_arn: @alb_target_group, 
          targets: [
            {
              id: @instance_id, 
            }, 
          ], 
        })
        self.puts "wait for deregistration of #{@instance_id} from #{@alb_target_group}"
        @client.wait_until(
          :target_deregistered,
          target_group_arn: @alb_target_group,
          targets: [
            {
              id: @instance_id
            }
          ]
        )
      end

      def self.post_description
        'register instance to loadbalancer'
      end

      def post
        self.puts "register #{@instance_id} to #{@alb_target_group}"
        @client.register_targets({
          target_group_arn: @alb_target_group, 
          targets: [
            {
              id: @instance_id, 
            }, 
          ], 
        })
        self.puts "wait for registration of #{@instance_id} to #{@alb_target_group}"
        @client.wait_until(
          :target_in_service,
          target_group_arn: @alb_target_group,
          targets: [
            {
              id: @instance_id
            }
          ]
        )
      end

      def skip?
        @switch_only or @alb_target_group.nil? or @alb_target_group.empty? or @instance_id.nil?
      end

      def self.show_always?
        true
      end
    end
  end
end
