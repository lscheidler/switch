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
require 'webmock/rspec'

class StubSocket
  def close
  end
end

class Aws::Waiters::Waiter
  def trigger_before_attempt(attempts)
    throw :success
  end
end

describe Switch::Plugins::AwsALB do
  let(:stub_resource) { Aws::ElasticLoadBalancingV2::Resource.new(stub_responses: true, region: 'eu-central-1') }

  before(:all) do
    initialize_test_data
    @config.dryrun = true
    @config.aws_region = 'eu-central-1'
    @config.alb_target_group = "arn:aws:elasticloadbalancing:<region>:<account-id>:targetgroup/<target-group-name>/<target-group-id>"
    @instance_id = "i-0123456789abcdef0"

    @pm = PluginManager.instance
  end

  after(:all) do
    cleanup
  end

  before do
    stub_request(:get, "http://169.254.169.254/latest/meta-data/instance-id").
      to_return(body: @instance_id)
  end

  it 'should deregister' do
    expect(Aws::ElasticLoadBalancingV2::Resource).to receive(:new).and_return(stub_resource)
    expect(stub_resource.client).to receive(:deregister_targets).with({:target_group_arn=>"arn:aws:elasticloadbalancing:<region>:<account-id>:targetgroup/<target-group-name>/<target-group-id>", :targets=>[{:id=>"i-0123456789abcdef0"}]}) {true}
    @plugin = @pm['Switch::Plugins::AwsALB'].new(@config)
    expect{@plugin.pre}.to output( "deregister i-0123456789abcdef0 from arn:aws:elasticloadbalancing:<region>:<account-id>:targetgroup/<target-group-name>/<target-group-id>
wait for deregistration of i-0123456789abcdef0 from arn:aws:elasticloadbalancing:<region>:<account-id>:targetgroup/<target-group-name>/<target-group-id>\n"
    ).to_stdout
  end

  it 'should register' do
    expect(Aws::ElasticLoadBalancingV2::Resource).to receive(:new).and_return(stub_resource)
    expect(stub_resource.client).to receive(:register_targets).with({:target_group_arn=>"arn:aws:elasticloadbalancing:<region>:<account-id>:targetgroup/<target-group-name>/<target-group-id>", :targets=>[{:id=>"i-0123456789abcdef0"}]}) {true}
    @plugin = @pm['Switch::Plugins::AwsALB'].new(@config)
    expect{@plugin.post}.to output( "register i-0123456789abcdef0 to arn:aws:elasticloadbalancing:<region>:<account-id>:targetgroup/<target-group-name>/<target-group-id>
wait for registration of i-0123456789abcdef0 to arn:aws:elasticloadbalancing:<region>:<account-id>:targetgroup/<target-group-name>/<target-group-id>\n"
    ).to_stdout
  end
end
