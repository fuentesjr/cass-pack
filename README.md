Cass-Pack
================================================================================
Cass-Pack is short for Cassandra Pack. It is basically a capistrano script with
only a few Chef cookbooks needed to easily deploy a Cassandra cluster.  It 
works by using a Capistrano script that installs the Chef binaries via the
distrobutions package mechanism (apt or yum) and then pushes a tarball of
recipes which are executed. At this point it has only been tested on chef-solo, 
but it should work with chef-server with minor modifications.

Credit to Benjamin Black for his work:
  http://github.com/b/cookbooks/tree/cassandra

Credit also to James Golick and Jonathan Ellis
  http://github.com/jamesgolick/cassandra-munin-plugins.git
