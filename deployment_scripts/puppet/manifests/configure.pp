notice('MODULAR: fuel-plugin-telemetry: configure.pp')

# Let's use already defined params for ceilometer
include ::ceilometer::params

$plugin_data          = hiera_hash('telemetry', undef)
$resource_api         = $plugin_data['resource_api']
$event_api            = $plugin_data['event_api']
$network_metadata     = hiera_hash('network_metadata')
$elasticsearch_server = hiera('telemetry::elasticsearch::server')
$elasticsearch_port   = hiera('telemetry::elasticsearch::rest_port')
$aodh_nodes           = hiera('aodh_nodes')


$ceilometer_service_name = $::ceilometer::params::api_service_name
$event_pipeline_file     = '/etc/ceilometer/event_pipeline.yaml'
$ceilometer_publishers   = 'direct'

$influxdb_address  = hiera('telemetry::influxdb::address')
$influxdb_port     = hiera('telemetry::influxdb::port')
$influxdb_database = hiera('telemetry::influxdb::database')
$influx_user       = hiera('telemetry::influxdb::user')
$influx_password   = hiera('telemetry::influxdb::password')

$metering_connection = "stacklight://${influx_user}:${influx_password}@${influxdb_address}:${influxdb_port}/${influxdb_database}"

if $event_api {
  if ($elasticsearch_server != '' and $elasticsearch_port != ''){
    $event_connection    = "es://${elasticsearch_server}:${elasticsearch_port}"
  }
  else{
    fail ("elasticsearch_server and elasticsearch_port variables can't be empty strings")
  }
}

if $resource_api {
  if ($elasticsearch_server != '' and $elasticsearch_port != ''){
    $resource_connection = "es://${elasticsearch_server}:${elasticsearch_port}"
  }
  else{
    fail ("elasticsearch_server and elasticsearch_port variables can't be empty strings")
  }
}

$packages = {
  'ceilometer-collector' => {
    # keep 'absent' instead of 'purged' for idempotence
    ensure => 'absent',
    require => Service['ceilometer-collector'],
  },
  'python-influxdb' => {
    ensure => 'present',
  },
  'python-elasticsearch' => {
    ensure => 'present',
  },
}

create_resources(package, $packages)

# Stop not needed any more service
service { 'ceilometer-collector':
  ensure    => stopped,
  enable    => false,
  hasstatus => true,
}

# Kafka integration

if hiera('telemetry::kafka::enabled') {

  ceilometer_config { 'oslo_messaging_kafka/consumer_group':        value => 'ceilometer' }

  $kafka_ips  = hiera('telemetry::kafka::broker_list')
  $kafka_url  = "moskafka://${kafka_ips}"
  $rabbit_url = 'rabbit://'

  ceilometer_config { 'DEFAULT/transport_url':                      value => $kafka_url }
  ceilometer_config { 'notification/messaging_urls':                value => [$kafka_url,$rabbit_url] }
  ceilometer_config { 'oslo_messaging_notifications/transport_url': value => $kafka_url }

  ceilometer_config { 'compute/resource_update_interval':           value => 600 }

  # remove mongo url
  ceilometer_config { 'database/connection':                        ensure => absent }

  # Coordination
  $zookeeper_list = hiera('telemetry::kafka::zookeeper_list')
  $zookeeper_url  = "zookeeper://${zookeeper_list}"
  ceilometer_config { 'coordination/backend_url': value => $zookeeper_url }
  aodh_config { 'coordination/backend_url':       value => $zookeeper_url }

  package { 'python-kafka':
    ensure => '1.2.5-1~u14.04+mos1'
  } ->
  package { 'python-oslo.messaging.kafka': }

}

ceilometer_config { 'database/metering_connection':   value => $metering_connection }
if $resource_api {
  ceilometer_config { 'database/resource_connection': value => $resource_connection }
}
else {
  ceilometer_config { 'database/resource_connection': value => 'es://localhost:9200' }
}
if $event_api {
  ceilometer_config { 'notification/store_events':    value => True }
  ceilometer_config { 'database/event_connection':    value => $event_connection }
}
else {
  ceilometer_config { 'notification/store_events':    value => false }
  ceilometer_config { 'database/event_connection':    value => 'log://' }
}
ceilometer_config { 'notification/workers': value => max($::processorcount/3,1) }

# Workaround for fixing Ceilometer bug in MOS9.x
file { '/usr/lib/python2.7/dist-packages/ceilometer/event/storage/impl_elasticsearch.py':
  ensure  => 'present',
  content => file( 'telemetry/ceilometer_fixes/impl_elasticsearch.py' ),
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  notify  => Service['ceilometer-service','ceilometer-agent-notification'],
  require => File['impl_elasticsearch.pyc'],
}

file {'/usr/lib/python2.7/dist-packages/ceilometer/event/storage/impl_elasticsearch.pyc':
  ensure => 'absent',
  alias  => 'impl_elasticsearch.pyc',
}

file { '/usr/lib/python2.7/dist-packages/ceilometer/storage/impl_stacklight.py':
  ensure  => 'present',
  content => file( 'telemetry/ceilometer_fixes/impl_stacklight.py' ),
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  notify  => Service['ceilometer-service','ceilometer-agent-notification'],
  require => File['impl_stacklight.pyc'],
}

file {'/usr/lib/python2.7/dist-packages/ceilometer/storage/impl_stacklight.pyc':
  ensure => 'absent',
  alias  => 'impl_stacklight.pyc',
}

file { '/usr/lib/python2.7/dist-packages/ceilometer/storage/metrics':
  ensure  => 'directory',
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  notify  => Service['ceilometer-service','ceilometer-agent-notification'],
}

file { '/usr/lib/python2.7/dist-packages/ceilometer/storage/metrics/__init__.py':
  ensure  => 'present',
  content => file( 'telemetry/ceilometer_fixes/metrics/__init__.py' ),
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  notify  => Service['ceilometer-service','ceilometer-agent-notification'],
}

file { '/usr/lib/python2.7/dist-packages/ceilometer/storage/metrics/units.py':
  ensure  => 'present',
  content => file( 'telemetry/ceilometer_fixes/metrics/units.py' ),
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  notify  => Service['ceilometer-service','ceilometer-agent-notification'],
}

service {'ceilometer-agent-notification':
  ensure     => $service_ensure,
  name       => $::ceilometer::params::agent_notification_service_name,
  enable     => $enabled,
  hasstatus  => true,
  hasrestart => true,
  tag        => 'ceilometer-agent-notification',
}

service { 'ceilometer-service':
  ensure     => $service_ensure,
  name       => $::ceilometer::params::api_service_name,
  enable     => $enabled,
  hasstatus  => true,
  hasrestart => true,
  tag        => 'ceilometer-service',
}

Ceilometer_config<||> ~> Service['ceilometer-service']

class { 'telemetry':
  event_pipeline_file => $event_pipeline_file,
  publishers          => $ceilometer_publishers,
}
