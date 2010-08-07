default_run_options[:pty] = true
ssh_options[:compression] = "none"
set :user, "root"
set :pub_key_filename, "id_rsa.pub"
CLUSTER = ['cass1', 'cass2', 'cass3', 'cass4']

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

#role :cluster, 'cass1', 'cass2', 'cass3', 'cass4'
role :cluster, *CLUSTER 

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
  task :copy_ssh_keys, :roles => [:cluster] do
    upload File.expand_path("~/.ssh/#{pub_key_filename}"), "~/", :via => :scp
    run <<-CMDS
      mkdir -p ~/.ssh/ && chmod 700 ~/.ssh &&
      cat ~/#{pub_key_filename} >> ~/.ssh/authorized_keys &&
      rm -f ~/#{pub_key_filename}
    CMDS
  end

  desc "Install Chef gem"
  task :install_chef do
    puts "gem install chef ohai"
  end

  desc "Install Riptano Repo"
  task :install_riptano_repo, :roles => [:cluster] do
    repo_file = "riptano-release-5-1.el5.noarch.rpm"
    run <<-CMDS
      wget http://rpm.riptano.com/EL/5/x86_64/#{repo_file} &&
      rpm -ivh #{repo_file}
    CMDS
    #run "yum install cassandra && chkconfig cassandra on"
  end

  desc "Provision all servers"
  task :provision_all, :roles => [:cluster] do
    puts "Done!"
  end
end
