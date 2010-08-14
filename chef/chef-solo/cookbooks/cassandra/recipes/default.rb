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

<<RPOFILES
http://rpm.riptano.com/EL/5/i386/:        riptano-release-5-1.el5.noarch.rpm
http://rpm.riptano.com/EL/5/x86_64/:      riptano-release-5-1.el5.noarch.rpm
http://rpm.riptano.com/EL/6/i386/:        riptano-release-5-1.el6.noarch.rpm
http://rpm.riptano.com/EL/6/x86_64/:      riptano-release-5-1.el6.noarch.rpm

http://rpm.riptano.com/Fedora/12/i386/:   riptano-release-5-1.fc12.noarch.rpm
http://rpm.riptano.com/Fedora/12/x86_64/: riptano-release-5-1.fc12.noarch.rpm
http://rpm.riptano.com/Fedora/13/i386/:   riptano-release-5-1.fc13.noarch.rpm
http://rpm.riptano.com/Fedora/13/x86_64/: riptano-release-5-1.fc13.noarch.rpm
http://rpm.riptano.com/Fedora/14/i386/:   riptano-release-5-1.fc14.noarch.rpm 
http://rpm.riptano.com/Fedora/14/x86_64/: riptano-release-5-1.fc14.noarch.rpm 
RPOFILES

case node[:platform]
when "centos","redhat","fedora"
  def get_riptano_release_info(os, base_version, architecture)
    #TODO: see if architecture always in {i386, x86_64} [fedora might have i686]
    repo_pkg_version = "5-1"
    distro_dir = { "centos" => "EL", "redhat" => "EL", "fedora" => "Fedora" }[node[:platform]] 
    rpm_filename = "riptano-release-#{repo_pkg_version}.el#{base_version}.noarch.rpm"
    url = "http://rpm.riptano.com/#{distro_dir}/#{base_version}/#{architecture}/#{rpm_filename}"
  end

  repo_info = get_riptano_release_info(node[:platform], node[:platform_version].to_i, node[:kernel][:machine])
  remote_file "/tmp/#{repo_info[:rpm_filename]}" do
    source package_info[:url] 
    owner "root"
    mode 0644
  end

  package "Riptano YUM Repo" do
    provider Chef::Provider::Package::Rpm
    source "/tmp/#{package_file}"
    options "--nogpgcheck"
    action :install
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
    only_if "apt-key export 'Eric Evans' | grep -q 'WARNING: nothing exported'" 
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
