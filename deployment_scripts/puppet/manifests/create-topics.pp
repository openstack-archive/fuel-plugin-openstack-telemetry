
notice('MODULAR: fuel-plugin-telemetry: create-topic.pp')

prepare_network_config(hiera_hash('network_scheme', {}))
$network_metadata         = hiera_hash('network_metadata')
$controllers              = get_nodes_hash_by_roles($network_metadata, ['controller', 'primary-controller'])
$controllers_amount       = count($controllers)
$notifications_partitions = max($controllers_amount/3,1)*$::processorcount
$metering_partitions      = $controllers_amount

$brokerlist               = hiera('telemetry::kafka::nodes_list')
$replication_factor       = count($brokerlist)
$zookeeper_ip             = $brokerlist[0]
$zookeeper_address        = "${zookeeper_ip}:2181"
$script_location          = '/tmp/create-topics.sh'

file { $script_location:
  owner   => 'root',
  group   => 'root',
  mode    => '0740',
  content => template('telemetry/create-topic.sh.erb'),
}

exec { "run_${script_location}":
  command => $script_location,
  require => File[$script_location],
}

exec { "remove_${script_location}":
  command => "/bin/rm -f ${script_location}",
  require => Exec["run_${script_location}"],
}
