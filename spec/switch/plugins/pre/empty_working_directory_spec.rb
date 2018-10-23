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

describe Switch::Plugins::Pre::EmptyWorkingDirectory do
  before(:all) do
    initialize_test_data
    create_working_directory_data

    @pm = PluginManager.instance
    @plugin = @pm['Switch::Plugins::Pre::EmptyWorkingDirectory'].new(@config)
  end

  after(:all) do
    cleanup
  end

  it 'should empty working directory' do
    expect(Dir.glob("#{@config.destination_directory}/wrapper/#{@config.application}/work/**/**")).to eq(
      [
        File.join(@config.destination_directory + "/wrapper/test-app/work/Catalina"),
        File.join(@config.destination_directory + "/wrapper/test-app/work/Catalina/localhost"),
        File.join(@config.destination_directory + "/wrapper/test-app/work/Catalina/localhost/test.txt")
      ]
    )
    expect{@plugin.pre}.to output("""remove all files in #{@config.destination_directory}/wrapper/#{@config.application}/work/*\n""").to_stdout
    expect(Dir.glob("#{@config.destination_directory}/wrapper/#{@config.application}/work/**/**")).to eq([])
  end

  describe 'switch only' do
    before(:all) do
      @config.switch_only = true
      @plugin = @pm['Switch::Plugins::Pre::EmptyWorkingDirectory'].new(@config)
    end

    after(:all) do
      @config.switch_only = nil
    end

    it 'should not empty working directory' do
      expect(@plugin.skip?).to be(true)
    end
  end
end
