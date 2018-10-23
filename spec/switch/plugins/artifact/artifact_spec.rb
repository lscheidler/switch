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

describe Switch::Plugins::Artifact::Artifact do
  before(:all) do
    initialize_test_data
    @config.dryrun = true

    @pm = PluginManager.instance
  end

  after(:all) do
    cleanup
  end

  it 'should retrieve artifact' do
    expect{@pm['Switch::Plugins::Artifact::Artifact'].new(@config)}.to output(/sudo -n artifact --get -a #{@config.application} -e #{@config.environment_name} -v #{@config.version} -d #{@config.destination_directory}/).to_stdout
  end
end
