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

require "spec_helper"

describe Switch::Plugins::Notification::Graphite do
  before(:all) do
    initialize_test_data
    create_release_data
    @config.graphite_host = '127.0.0.1'
    @config.graphite_port = '123456'

    @pm = PluginManager.instance
    @plugin = @pm['Switch::Plugins::Notification::Graphite'].new(@config)
  end

  after(:all) do
    cleanup
  end

  it 'should send notification to graphite' do
    expect{@plugin.notification}.to output(/notify graphite about deployment/).to_stdout
    TCPSocket.stream.rewind
    expect(TCPSocket.stream.read).to match(/^switch\.#{@config.environment_name}\.[^.]*\.#{@config.application}.#{@config.version.gsub('.', '_')} 1 [0-9]{10}$/)
  end

  describe 'switch only' do
    before(:all) do
      @config.switch_only = true
      @plugin = @pm['Switch::Plugins::Notification::Graphite'].new(@config)
    end

    after(:all) do
      @config.switch_only = nil
    end

    it 'should not skip graphite notification' do
      expect(@plugin.skip?).to be(false)
    end
  end
end
