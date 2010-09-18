#
# Author:: Salvador Fuentes (<fuentesjr@gmail.com>)
# Cookbook Name:: cassandra
# Recipe:: backups 
#
# Copyright 2010, Salvador Fuentes
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
#

cron "snapshot" do
  user "root"
  hour "11"
  minute "1"
  command "/usr/bin/env nodetool --host localhost --port 8585 snapshot",
end

cron "clear snapshot" do
  user "root"
  hour "0"
  minute "1"
  command "/usr/bin/env nodetool --host localhost --port 8585 clearsnapshot && /usr/bin/env nodetool --host localhost --port 8585 snapshot",
end
