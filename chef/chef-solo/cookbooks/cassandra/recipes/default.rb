#
# Author:: Benjamin Black (<b@b3k.us>)
# Cookbook Name:: cassandra
# Recipe:: default
#
# Copyright 2010, Benjamin Black
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

include_recipe "cassandra::iptables"

#BUG: node[:ipaddress] always empty (bug in chef-solo?)
node_ip_addr = node[:ipaddress]
node_ip_addr = node_ip_addr || %x(/sbin/ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}').gsub(/\n/, '')

node[:cassandra][:listen_addr] = node_ip_addr 
node[:cassandra][:thrift_addr] = node_ip_addr 

case node[:platform]
when "centos","redhat","fedora"
  ruby_block "refresh_yum_cache" do
    block do
      Chef::Provider::Package::Yum::YumCache.instance.flush
    end
    action :nothing
  end

  repo_pkg_info = CassandraHelper::get_riptano_repo_pkg_info(node[:platform], node[:platform_version].to_i, node[:kernel][:machine])
  remote_file "/tmp/#{repo_pkg_info[:filename]}" do
    source repo_pkg_info[:url] 
    owner "root"
    mode 0644
  end

  package "Riptano YUM Repo" do
    source "/tmp/#{repo_pkg_info[:filename]}"
    options "--nogpgcheck"
    action :install
    notifies :create, resources("ruby_block[refresh_yum_cache]"), :immediately
  end
when "debian","ubuntu"
  execute "apt-get update" do
    action :nothing
  end

  template "/etc/apt/sources.list.d/cassandra.list" do
    owner "root"
    mode "0644"
    source "cassandra.list.erb"
    notifies :run, resources("execute[apt-get update]"), :immediately
  end

  execute "gpg --keyserver wwwkeys.eu.pgp.net --recv-keys F758CE318D77295D && gpg --export --armor F758CE318D77295D | apt-key add -" do
    not_if "apt-key export 'Eric Evans' | grep -vq 'WARNING: nothing exported'" 
    notifies :run, resources("execute[apt-get update]"), :immediately
  end
end

package "cassandra" do
  action :install
end

service "cassandra" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

template "/etc/cassandra/storage-conf.xml" do
  source "storage-conf.xml.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "cassandra")
end

include_recipe "cassandra::munin"
