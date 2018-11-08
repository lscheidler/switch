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

describe Switch::Plugins::SwitchCurrentLink do
  before(:all) do
    initialize_test_data

    @pm = PluginManager.instance
    @plugin = @pm['Switch::Plugins::SwitchCurrentLink'].new(@config)
  end

  after(:all) do
    cleanup
  end

  it 'should switch current link' do
    expect{@plugin.switch}.to output(/remove current link\ncurrent link doesn't exist.\ncreate current link with 0\.1\.0\nlog: user=[^ ]* environment=staging application=test-app from=0.0.1 to=0.1.0\n/m).to_stdout
    expect(File.symlink? File.join(@config.destination_directory, @config.application, 'current')).to be(true)
    expect(File.readlink File.join(@config.destination_directory, @config.application, 'current')).to eq(File.join(@config.destination_directory, @config.application, 'releases', @config.version))
  end

  describe 'switch only' do
    before(:all) do
      @config.switch_only = true
      @plugin = @pm['Switch::Plugins::SwitchCurrentLink'].new(@config)
    end

    after(:all) do
      @config.switch_only = nil
    end

    it 'should not skip switching current link' do
      expect(@plugin.skip?).to be(false)
    end
  end
end
