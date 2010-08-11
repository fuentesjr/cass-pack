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

#include_recipe "java"

case node[:platform]
when "centos","redhat","fedora"
  package_file = "riptano-release-5-1.el5.noarch.rpm"
  remote_file "/tmp/#{package_file}" do
    source "http://rpm.riptano.com/EL/5/x86_64/" + package_file
    owner "root"
    mode 0644
  end

  rpm_package "Riptano Repo" do
    source "/tmp/#{package_file}"
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

  execute "gpg --keyserver wwwkeys.eu.pgp.net --recv-keys F758CE318D77295D && gpg --export --armor F758CE318D77295D | sudo apt-key add -" do
    not_if "apt-key export 'Eric Evans <eevans@apache.org>'"
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
