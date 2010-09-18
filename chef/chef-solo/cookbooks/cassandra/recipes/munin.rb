#
# Author:: Salvador Fuentes (<fuentesjr@gmail.com>)
# Cookbook Name:: cassandra
# Recipe:: munin
#
# Copyright 2010, Benjamin Black
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
include_recipe "munin::client"

jmx_utils = %w( jmx_ jmxquery.jar )

directory "/usr/share/munin/plugins" do
  mode 0755
  owner "root"
  group "root"
  recursive true
end

jmx_utils.each do |jmx_util|
  cookbook_file "/usr/share/munin/plugins/#{jmx_util}" do
    cookbook "cassandra"
    source "munin/#{jmx_util}"
    owner "root"
    group "root"
    mode 0755
  end
end

plugin_names = %w(
  compactions_bytes
  compactions_pending
  flush_stage_pending
  hh_pending
  jvm_cpu
  jvm_memory
  ops_pending
  storageproxy_latency
  storageproxy_ops
)

plugin_names.each do |plugin_name|
  cookbook_file "/usr/share/munin/plugins/#{plugin_name}.conf" do
    cookbook "cassandra"
    source "munin/#{plugin_name}.conf"
    owner "root"
    group "root"
    mode 0644
  end
end

plugin_names.each do |plugin_name|
  munin_plugin "jmx_" do
    plugin plugin_name
    # create_file true
    # enable false if jmx_utils.include?(plugin_name)
  end
end

node_ip_addr = %x(/sbin/ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}').gsub(/\n/, '')
include_recipe "munin::server" if node[:munin][:servers].include?({ "ipaddress" => node_ip_addr })

bash "remove basic auth" do
  code <<-EOH
  sed -i'' -e 's/^\(Auth.*\)$/#\1/' /var/www/html/munin/.htaccess
  sed -i'' -e 's/^\(require valid-user\).*/#\1/' /var/www/html/munin/.htaccess
  EOH
  not_if "grep -q '^#Auth'" 
end

