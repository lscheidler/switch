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

require 'socket'

require_relative "../common"

module Switch
  module Plugins
    module Notification
      class Graphite < Switch::Plugins::Common
        plugin_group :notification

        plugin_argument :graphite_host, validator: Proc.new {|x| not x.nil? and not x.empty?}
        plugin_argument :graphite_port, optional: true, default: "2003"
        plugin_argument :application
        plugin_argument :environment_name
        plugin_argument :version

        def self.notification_description
          'notify graphite about deployment'
        end

        def notification
          self.puts notification_description

          unless @dryrun
            begin
              TCPSocket.open(@graphite_host, @graphite_port) do |sock|
                sock.setsockopt(:IP, :TTL, 255)

                metric_data = "switch.#{@environment_name}.#{Socket.gethostname[/^[^.]*/]}.#{@application.gsub('/', '-')}.#{@version.gsub('.', '_')} 1 #{Time.now.to_i}\n"
                sock.send(metric_data, 0)
              end
            rescue Errno::ETIMEDOUT
              fail 'Connection timeout for ' + @graphite_host + ':' + @graphite_port
            rescue Errno::ECONNREFUSED
              fail 'Connection refused for ' + @graphite_host + ':' + @graphite_port
            end
          end
        end

        def self.show_always?
          true
        end
      end
    end
  end
end
