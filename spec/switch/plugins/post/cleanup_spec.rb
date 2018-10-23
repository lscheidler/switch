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

describe Switch::Plugins::Post::Cleanup do
  before(:all) do
    initialize_test_data
    create_release_data
    @config.dryrun = true

    @pm = PluginManager.instance
    @plugin = @pm['Switch::Plugins::Post::Cleanup'].new(@config)
  end

  after(:all) do
    cleanup
  end

  it 'should auto cleanup old releases' do
    expect{@plugin.post}.to output(/sudo -n -u app switch-cleanup -a test-app -v 0.0.1/).to_stdout
  end

  describe 'switch only' do
    before(:all) do
      @config.switch_only = true
      @plugin = @pm['Switch::Plugins::Post::Cleanup'].new(@config)
    end

    after(:all) do
      @config.switch_only = nil
    end

    it 'should skip auto cleanup' do
      expect(@plugin.skip?).to be(true)
    end
  end
end
