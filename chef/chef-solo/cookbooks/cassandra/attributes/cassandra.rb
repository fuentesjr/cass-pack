# STRUCTURE OF THE CASSANDRA DATA
# 
#   {:id : "clusters",
#     {<cluster name> =>
#       {:keyspaces =>
#         {<keyspace name> => {
#           :columns => {<column name> => {<attrib> => <value>, ...}, ...},
#           :replica_placement_strategy => <strategy>,
#           :replication_factor => <factor>,
#           :end_point_snitch => <snitch>
#         }},
#        <other per cluster settings>
#       }
#     }
#   }

example_keyspace_config = { 
  "Keyspace1" => { 
    "replica_placement_strategy" => "org.apache.cassandra.locator.RackUnawareStrategy",
    "replication_factor" => 1,
    "end_point_snitch" => "org.apache.cassandra.locator.EndPointSnitch",
    "columns" => { 
      "Standard1" => {
        "CompareWith" => "BytesType"
      },
      "Standard2" => {
        "CompareWith" => "UTF8Type",
        "KeysCached" => "100%"
      },
      "StandardByUUID1" => {
        "CompareWith" => "TimeUUIDType"
      },
      "Super1" => {
        "ColumnType" => "Super",
        "CompareWith" => "BytesType",
        "CompareSubcolumnsWith" => "BytesType"
      },
      "Super2" => {
        "ColumnType" => "Super",
        "CompareWith" => "UTF8Type",
        "CompareSubcolumnsWith" => "UTF8Type",
        "RowsCached" => "10000",
        "KeysCached" => "50%",
        "Comment" => "A column family with supercolumns, whose column and subcolumn names are UTF8 strings"
      }
    }
  }
}

default.cassandra.cluster_name  = "TestCluster"
default.cassandra.auto_bootstrap  = false
default.cassandra.keyspaces = example_keyspace_config
default.cassandra.authenticator = "org.apache.cassandra.auth.AllowAllAuthenticator"
default.cassandra.partitioner = "org.apache.cassandra.dht.OrderPreservingPartitioner"
default.cassandra.initial_token = ""
default.cassandra.commit_log_dir = "/var/lib/cassandra/commitlog"
default.cassandra.data_file_dirs = ["/var/lib/cassandra/data"]
default.cassandra.callout_location = "/var/lib/cassandra/callouts"
default.cassandra.staging_file_dir = "/var/lib/cassandra/staging"
default.cassandra.seeds = ["127.0.0.1"]
default.cassandra.rpc_timeout = 5000
default.cassandra.commit_log_rotation_threshold = 128
default.cassandra.jmx_port = 8080
default.cassandra.listen_addr = "localhost"
default.cassandra.storage_port = 7000
default.cassandra.thrift_addr = "localhost"
default.cassandra.thrift_port = 9160
default.cassandra.thrift_framed_transport = false
default.cassandra.disk_access_mode = "auto"
default.cassandra.sliced_buffer_size = 64
default.cassandra.flush_data_buffer_size = 32
default.cassandra.flush_index_buffer_size = 8
default.cassandra.column_index_size = 64
default.cassandra.memtable_throughput = 64
default.cassandra.binary_memtable_throughput = 256
default.cassandra.memtable_ops = 0.3
default.cassandra.memtable_flush_after = 60
default.cassandra.concurrent_reads = 8
default.cassandra.concurrent_writes = 32
default.cassandra.commit_log_sync = "periodic"
default.cassandra.commit_log_sync_period = 10000
default.cassandra.gc_grace = 864000
