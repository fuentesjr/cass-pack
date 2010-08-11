default_run_options[:pty] = true 
ssh_options[:compression] = "none"
#set :user, "root"
set :pub_key_filename, "id_rsa.pub"
CASSANDRA_CLUSTER = ['cass1', 'cass2', 'cass3', 'cass4']
CHEF_SERVER = 'chef'

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

#role :cluster, 'cass1', 'cass2', 'cass3', 'cass4'
role :cass_cluster, *CASSANDRA_CLUSTER 
role :testvm, 'cke-testvm1'
role :chef, 'chef'
role :buntuvm, 'buntuvm'

# =============================================================================
# TASK CHAINS 
# =============================================================================
before "devops:install_chef", "devops:copy_ssh_keys"

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

# Tasks may take advantage of several different helper methods to interact
# with the remote server(s). These are:
#
# * run(command, options={}, &block): execute the given command on all servers
#   associated with the current task, in parallel. The block, if given, should
#   accept three parameters: the communication channel, a symbol identifying the
#   type of stream (:err or :out), and the data. The block is invoked for all
#   output from the command, allowing you to inspect output and act
#   accordingly.
# * sudo(command, options={}, &block): same as run, but it executes the command
#   via sudo.
# * delete(path, options={}): deletes the given file or directory from all
#   associated servers. If :recursive => true is given in the options, the
#   delete uses "rm -rf" instead of "rm -f".
# * put(buffer, path, options={}): creates or overwrites a file at "path" on
#   all associated servers, populating it with the contents of "buffer". You
#   can specify :mode as an integer value, which will be used to set the mode
#   on the file.
# * render(template, options={}) or render(options={}): renders the given
#   template and returns a string. Alternatively, if the :template key is given,
#   it will be treated as the contents of the template to render. Any other keys
#   are treated as local variables, which are made available to the (ERb)
#   template.

namespace :devops do
  desc "Report uptime on all servers"
  task :default do
    run "uptime"
  end

  desc "Copy ssh keys to servers for passwordless entry"
  task :copy_ssh_keys, :roles => [:cass_cluster] do
    upload File.expand_path("~/.ssh/#{pub_key_filename}"), "~/", :via => :scp
    run <<-CMDS
      mkdir -p ~/.ssh/ && chmod 700 ~/.ssh &&
      cat ~/#{pub_key_filename} >> ~/.ssh/authorized_keys &&
      rm -f ~/#{pub_key_filename}
    CMDS
  end

  desc "Install Chef gem on clients"
  task :install_chef, :roles => [:cass_cluster] do
    puts "gem install chef ohai"
  end

  desc "Install Riptano Repo"
  task :install_riptano_repo, :roles => [:cass_cluster] do
    repo_file = "riptano-release-5-1.el5.noarch.rpm"
    run <<-CMDS
      wget http://rpm.riptano.com/EL/5/x86_64/#{repo_file} &&
      rpm -ivh #{repo_file}
    CMDS
    #run "yum install cassandra && chkconfig cassandra on"
  end

  desc "Provision all servers"
  task :provision_all, :roles => [:cass_cluster] do
    puts "TBD"
  end

  namespace :chef do
    desc "Testing ssh keys"
    task :cp_keys, :roles => [:buntuvm] do
      upload File.expand_path("~/.ssh/#{pub_key_filename}"), "~/", :via => :scp
      run <<-CMDS
        mkdir -p ~/.ssh/ && chmod 700 ~/.ssh &&
        cat ~/#{pub_key_filename} >> ~/.ssh/authorized_keys &&
        rm -f ~/#{pub_key_filename}
      CMDS
    end

    desc "Testing Ben's Cassandra Cookbook"
    task :test1, :roles => [:buntuvm] do
      chef_bin = "/var/lib/gems/1.8/bin/chef-solo"
      #sudo "apt-get install -y git-core ruby ruby-dev build-essential wget libopenssl-ruby rubygems"
      #sudo "gem install --no-ri --no-rdoc chef ohai --source http://gems.opscode.com --source http://gems.rubyforge.org"
      sudo "rm -rf /etc/chef"
      sudo "mkdir -p /etc/chef"
      sudo "git clone git://github.com/fuentesjr/chef-101.git /etc/chef" do |channel, stream, data|
        #channel.send_data("yes\n")
      end
      #sudo "echo 'export PATH=/var/lib/gems/1.8/bin:$PATH' | sudo tee -a  /etc/bash.bashrc"
      #sudo "export PATH=/var/lib/gems/1.8/bin:$PATH"
      chef_path = "/etc/chef"
      #sudo "chef-solo --help", :shell => "/bin/bash", :env => {"PATH" => "/var/lib/gems/1.8/bin:$PATH"}
      #sudo "#{chef_bin} --help", :shell => "/bin/bash", :env => {"PATH" => "/var/lib/gems/1.8/bin:$PATH"}
      sudo "#{chef_bin} -l debug -c #{chef_path}/config/solo.rb -j #{chef_path}/config/dna.json"
    end

    desc "Configure client using Chef Solo"
    task :solo, :roles => [:testvm] do
      payload_filename = 'chef_payload.tgz'
      system "tar -zcvf #{payload_filename} -C chef chef-solo"
      upload "./#{payload_filename}", "~/", :via => :scp
      run <<-CMDS
        sudo gem install chef ohai &&
        mkdir -p /etc/chef && 
        tar -zxvf #{payload_filename} -C /etc/chef &&
        cd /etc/chef/chef-solo && 
        sudo chef-solo -l debug -c config/solo.rb -j config/dna.json
      CMDS

      system "rm #{payload_filenam}"
    end

    desc "Provision (install recipes on) Chef Nodes"
    task :provision_nodes, :roles => [:cass_cluster] do
      run "chef-client"
    end

    desc "Configure Chef Client on Nodes"
    task :prep_nodes, :roles => [:cass_cluster] do
      # See http://wiki.opscode.com/display/chef/Hello+World+example 
      run <<-CMDS
        rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-3.noarch.rpm &&
        rpm -Uvh http://download.elff.bravenet.com/5/x86_64/elff-release-5-3.noarch.rpm &&
        yum install -y chef &&
        sudo /sbin/service chef-client start &&
        sudo /sbin/chkconfig chef-client on &&
        cd /etc/chef
        scp root@#{CHEF_SERVER}:/etc/chef/validation.pem . &&

        chef_server_url  "http://#{CHEF_SERVER}:4000"
        chef-client &&
        rm /etc/chef/validation.pem
      CMDS

      puts "Done!"
    end

    desc "Configure Chef Server"
    task :config_server, :roles => [:chef] do
      # See the following links for info:
      # http://wiki.opscode.com/display/chef/Hello+World+example 
      # http://wiki.opscode.com/display/chef/Installation+on+RHEL+and+CentOS+5+with+RPMs
      run <<-CMDS
        rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-3.noarch.rpm &&
        rpm -Uvh http://download.elff.bravenet.com/5/x86_64/elff-release-5-3.noarch.rpm &&
        yum install -y chef-server &&
        for svc in couchdb rabbitmq-server chef-solr chef-solr-indexer chef-server; do /sbin/service $svc start && /sbin/chkconfig $svc on done &&
        yum install -y chef-server-webui &&
        /sbin/service chef-server-webui start &&
        /sbin/chkconfig chef-server-webui on &&
        yum install -y chef &&
        sudo /sbin/service chef-client start &&
        sudo /sbin/chkconfig chef-client on &&

        # /sbin/iptables -A -i eth0 -j ACCEPT OPEN PORT 4000 and 4040
        cd /opt &&
        yum install -y  git &&
        git clone git://github.com/opscode/chef-repo.git  

        knife configure -i

        cd /opt/chef-repo
        rm -rf cookbooks
        git clone git://github.com/opscode/cookbooks

        knife cookbook upload -a -o /opt/chef-repo/cookbooks
      CMDS

      #put File.read("roles/default.rb"), "/opt/chef-repo/roles/default.rb", :via => :scp
      upload "roles/default.rb", "/opt/chef-repo/roles/default.rb", :via => :scp

      run <<-CMDS
        rake roles &&
        knife role show default &&
        git add cookbooks &&
        git add roles &&
        git commit -m "Added some cookbooks and an example role to use them."
      CMDS
    end
  end
end