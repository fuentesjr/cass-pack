#
# Author:: Salvador Fuentes (<fuentesjr@gmail.com>)
# Cookbook Name:: cassandra
# Recipe:: munin
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
include_recipe "munin::client"

# Might move this to jmx_ script/plugin
file "/var/lib/munin/plugin-state/yum.state" do
  owner "munin"
  group "munin"
  mode  "0664"
  action :create
end

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

column_family_plugin_names = Array.new
fields = %w( keycache latency livesize ops rowcache sstables )

node[:cassandra][:keyspaces].each_pair do |kname, keyspace|
  keyspace[:columns].each_key do |cname|
    fields.each do |field|
      column_family_plugin_names << column_family_plugin = "#{kname}_#{cname}_#{field}"

      template "/usr/share/munin/plugins/#{column_family_plugin_name}.conf" do
        variables :keyspace => kname, :column_family => cname
        source "column_family_#{field}.conf.erb"
        owner "root"
        group "root"
        mode 0644
      end
    end
  end
end

plugin_names = %w( compactions_bytes compactions_pending 
  flush_stage_pending hh_pending jvm_cpu jvm_memory ops_pending 
  storageproxy_latency storageproxy_ops )

plugin_names.each do |plugin_name|
  cookbook_file "/usr/share/munin/plugins/#{plugin_name}.conf" do
    cookbook "cassandra"
    source "munin/#{plugin_name}.conf"
    owner "root"
    group "root"
    mode 0644
  end
end

plugins = plugin_names + column_family_plugin_names
plugins.each do |plugin_name|
  munin_plugin "jmx_" do
    plugin plugin_name
  end
end

node_ip_addr = node[:ipaddress]
node_ip_addr = node_ip_addr || %x(/sbin/ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}').gsub(/\n/, '')

if node[:munin][:servers].include?({ "ipaddress" => node_ip_addr })
  include_recipe "munin::server" 
  bash "remove basic auth" do
    only_if "grep -q '^Auth' /var/www/html/munin/.htaccess" 
    notifies :reload, resources(:service => "apache2")
    # Using single-quote heredoc keeps us from escaping capture group \1 and 
    # makes string easier to read
    code <<-'EOH'
    sed -i"" -e "s/^\(Auth.*\)$/#\1/" /var/www/html/munin/.htaccess
    sed -i"" -e "s/^\(require valid-user\).*/#\1/" /var/www/html/munin/.htaccess
    EOH
  end
end
