
notice('MODULAR: fuel-plugin-telemetry: create-topics.pp')

# Topic settings

prepare_network_config(hiera_hash('network_scheme', {}))
$network_metadata         = hiera_hash('network_metadata')
$controllers              = get_nodes_hash_by_roles($network_metadata, ['controller', 'primary-controller'])
$controllers_amount       = count($controllers)
$notifications_partitions = max($controllers_amount/3,1)*$::processorcount
$kafka_nodes_count        = count(hiera('telemetry::kafka::nodes_list'))
$metering_partitions      = $kafka_nodes_count*4

# Connection info

$brokerlist         = hiera('telemetry::kafka::nodes_list')
$replication_factor = count($brokerlist)
$zookeeper_ip       = $brokerlist[0]
$zookeeper_address  = "${zookeeper_ip}:2181"
$script_location    = '/tmp/create-topics.sh'

file { $script_location:
  owner   => 'root',
  group   => 'root',
  mode    => '0740',
  content => template('telemetry/create-topics.sh.erb'),
}

exec { "run_${script_location}":
  command => $script_location,
  require => File[$script_location],
}

exec { "remove_${script_location}":
  command => "/bin/rm -f ${script_location}",
  require => Exec["run_${script_location}"],
}
