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

def cleanup
  FileUtils.rm_rf @test_config[:destination_directory]
end
