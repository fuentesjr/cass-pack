Cass-Pack (Batteries Included)
================================================================================
Cass-Pack is short for Cassandra Pack. It is essentially a capistrano script with
a few Chef cookbooks to easily deploy and manage a Cassandra cluster.  It 
works by using a Capistrano script that installs the Chef binaries via the
distributions package mechanism (apt or yum) and then pushes a tarball of
recipes which are executed. At this point it has only been tested on chef-solo, 
but it should work with chef-server with minor modifications.

Credits
================================================================================
To Benjamin Black for his early work on:
  http://github.com/b/cookbooks/tree/cassandra

To James Golick and Jonathan Ellis for their work on the munin plugins
  http://github.com/jamesgolick/cassandra-munin-plugins.git

To Edward Capriolo for his Puppet work/idea:
  http://www.edwardcapriolo.com/roller/edwardcapriolo/entry/cassandra_backup_is_a_snap
