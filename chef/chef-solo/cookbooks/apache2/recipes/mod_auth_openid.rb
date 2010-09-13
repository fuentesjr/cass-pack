#
# Cookbook Name:: apache2
# Recipe:: mod_auth_openid
#
# Copyright 2008-2009, Opscode, Inc.
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

case node[:platform]
when "centos", "redhat", "fedora"
  %w{gcc-c++ openssl openssl-devel curl-devel expat-devel libtidy-devel 
    httpd-devel sqlite-devel pcre-devel mysql-devel}.each do |pkg|
    package pkg
  end

  remote_file "/tmp/libopkele-2.0.4.tar.gz" do
    source "http://kin.klever.net/dist/libopkele-2.0.4.tar.gz"
    mode 0644
  end

  bash "install libopkele" do
    cwd "/tmp"
    code <<-EOH
    tar zxvf libopkele-2.0.4.tar.gz
    cd libopkele-2.0.4 && ./configure --prefix=/usr
    make && make install
    cp /usr/lib64/libexpat.so /usr/lib/libexpat.so 
    EOH
    # temporary solution: http://keystoneit.wordpress.com/2008/03/05/storegrid-installation-on-64-bit-rhel-centos-systems/
    not_if { File.exists?("/usr/lib/pkgconfig/libopkele.pc") }
  end
when "debian", "ubuntu"
  %w{ apache2-prefork-dev libopkele-dev libopkele3 }.each do |pkg|
    package pkg
  end
end

remote_file "/tmp/mod_auth_openid-0.4.tar.gz" do
  source "http://butterfat.net/releases/mod_auth_openid/mod_auth_openid-0.4.tar.gz"
  mode 0644
end

bash "install mod_auth_openid" do
  cwd "/tmp"
  code <<-EOH
  export PKG_CONFIG_PATH=/usr/lib/pkgconfig:$PKG_CONFIG_PATH
  tar zxvf mod_auth_openid-0.4.tar.gz
  cd mod_auth_openid-0.4 && ./configure
  perl -pi -e "s/-i -a -n 'authopenid'/-i -n 'authopenid'/g" Makefile
  make && make install
  EOH
  not_if { File.exists?("/usr/lib/apache2/modules/mod_auth_openid.so") }
end

directory "/var/cache/apache2" do
  owner node[:apache][:user]
  mode 0755
  recursive true
end

file "/var/cache/apache2/mod_auth_openid.db" do
  owner node[:apache][:user]
  mode 0600
end

template "#{node[:apache][:dir]}/mods-available/authopenid.load" do
  source "mods/authopenid.load.erb"
  owner "root"
  group "root"
  mode 0644
  case node[:platform]
  when "centos", "redhat", "fedora"
    variables :libdir => "lib64", :apache_name => "httpd"
  when "debian", "ubuntu"
    variables :libdir => "lib", :apache_name => "apache2"
  end
end

apache_module "authopenid"

template "/usr/local/bin/mod_auth_openid.rb" do
  source "mod_auth_openid.rb.erb"
  owner node[:apache][:user]
  group node[:apache][:user]
  mode 0750
end

