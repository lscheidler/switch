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

describe Switch::Plugins::DockerTagAndPush do
  before(:all) do
    initialize_test_data
    @config.dryrun = true

    @pm = PluginManager.instance
    @plugin = @pm['Switch::Plugins::DockerTagAndPush'].new(@config)
    String.disable_colorization = true
  end

  after(:all) do
    cleanup
  end

  it 'should tag and push' do
    expect{@plugin.switch}.to output(
       """tag new docker image test-app-0.1.0 to test-app-staging
| docker tag <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-0.1.0 <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging
docker tag <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-0.1.0 <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging
push tag test-app-staging
| docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging
log: user=lscheidler environment=staging application=test-app from=0.0.1 to=0.1.0
tag previous docker image test-app-0.0.1 to test-app-staging-previous
| docker tag <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-0.0.1 <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging-previous
docker tag <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-0.0.1 <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging-previous
push tag test-app-staging-previous
| docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging-previous
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/<name>:test-app-staging-previous
"""
    ).to_stdout
  end
end
