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

require_relative 'plugins/common'

require_relative 'plugins/artifact/get_artifact'

require_relative 'plugins/pre/stop_process'
require_relative 'plugins/pre/empty_working_directory'

require_relative 'plugins/start_stop_process'
require_relative 'plugins/switch_previous_link'
require_relative 'plugins/switch_current_link'

require_relative 'plugins/post/upload_version_information'
require_relative 'plugins/post/start_process'
require_relative 'plugins/post/enable_application_process'
require_relative 'plugins/post/enable_systemd_process'

require_relative 'plugins/post/cleanup'
require_relative 'plugins/post/auto_cleanup'

require_relative 'plugins/notification/graphite'

require_relative 'plugins/version/current_version'
require_relative 'plugins/version/next_version'
require_relative 'plugins/version/s3_next_version'
