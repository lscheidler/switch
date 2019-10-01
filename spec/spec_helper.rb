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

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "switch"

Aws.config[:s3] = {
  stub_responses: {
    list_buckets: { buckets: [{name: 'my-bucket' }] }
  }
}

class OutputLogger
  def info msg
    puts 'log: ' + msg
  end
end

# monkey patch TCPSocket for graphite test
class TCPSocket
  def self.open host, port
    @@stream ||= StringIO.new
    yield self
  end

  def self.stream
    @@stream
  end

  def self.setsockopt level, optname, optval
  end

  def self.send mesg, flags
    @@stream.print mesg
  end
end

def initialize_test_data
  @bucket_name = 'my-bucket'
  @bucket_region = 'eu-central-1'

  @config = OverlayConfig::Config.new config_scope: 'switchTest'
  @test_config = {
    application: 'test-app',
    current_version: '0.0.1',
    destination_directory: get_temporary_directory('switch'),
    dryrun: false,
    environment_name: 'staging',
    output: Proc.new {|msg| puts msg},
    switch_log: OutputLogger.new,
    ecr_repository: '<account-id>.dkr.ecr.<region>.amazonaws.com/<name>',
    version: '0.1.0'
  }

  @config.insert(0, 'test', @test_config)

  Dir.mkdir File.join(@config.destination_directory, @config.application)

  @pwd = Dir.pwd
end

def get_temporary_directory key
  directory = nil
  Tempfile.open(['switch-','-' + key]) do |file|
    directory = file.path
    file.close!
  end
  Dir.mkdir directory
  FileUtils.chmod 'g=-rx,o=-rx', directory
  directory
end

def create_working_directory_data
  directory_tree = ['wrapper', @config.application, 'work', 'Catalina', 'localhost']
  dir = @config.destination_directory
  directory_tree.each do |d|
    dir = File.join(dir, d)
    Dir.mkdir dir
  end

  File.open(File.join(@config.destination_directory, 'wrapper', @config.application, 'work', 'Catalina', 'localhost', 'test.txt'), 'w') do |io|
    io.puts 'Hello World'
  end
end

def create_release_data
  dir = File.join(@config.destination_directory, @config.application, 'releases')
  Dir.mkdir dir

  1.upto(8) do |x|
    release_dir = File.join(dir, '0.0.' + x.to_s)
    Dir.mkdir release_dir

    File.open(File.join(release_dir, 'test.txt'), 'w') do |io|
      io.puts 'Hello World'
    end

    FileUtils.touch release_dir, :mtime => Time.now - (10-x)
  end
end

def cleanup
  FileUtils.rm_rf @test_config[:destination_directory]
end
