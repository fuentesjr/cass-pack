Cass-Pack (Batteries Included)
================================================================================
Cass-Pack is short for Cassandra Pack. It is essentially a capistrano script with
a few Chef cookbooks to easily deploy and manage a Cassandra cluster.  It 
works by using a Capistrano script that installs the Chef binaries via the
distributions package mechanism (apt or yum) and then pushes a tarball of
recipes which are executed. At this point it has only been tested on chef-solo, 
but it should work with chef-server with minor modifications.

Credit to Benjamin Black for his work on:
  http://github.com/b/cookbooks/tree/cassandra

And credit to Edward Capriolo for his Puppet work/idea:
  http://www.edwardcapriolo.com/roller/edwardcapriolo/entry/cassandra_backup_is_a_snap
