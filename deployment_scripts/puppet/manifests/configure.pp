notice('MODULAR: fuel-plugin-telemetry: configure.pp')

$packages = {
  'ceilometer-collector' => {
    # keep 'absent' instead of 'purged' for idempotence
    ensure => 'absent',
    require => Service["ceilometer-collector"],},
}

# TODO: stop collector only when qeue is empty*
# *wait utill all the events went from collector
# before stop collector service
# maybe service'collector' ensure stopped; require exec 'wait for qeue is empty'

create_resources(package, $packages)

service { 'ceilometer-collector':
    ensure     => stopped,
    enable     => false,
    hasstatus  => true,
}

# TODO 'set' default values when looking for via hiera
$aodh_nodes           = hiera('aodh_nodes')
$elasticsearch_node   = $aodh_nodes["$::hostname"]["network_roles"]["elasticsearch"]
$elasticsearch_port   = hiera('lma::collector::elasticsearch::rest_port')
$influxdb_vip         = $aodh_nodes["$::hostname"]["network_roles"]["influxdb_vip"]
$influxdb_port        = hiera('lma::collector::influxdb::port')
$influx_database      = hiera('lma::collector::influxdb::database')
$influx_user          = 'root' # hiera('lma::collector::influxdb::user')
$influx_password      = hiera('lma::collector::influxdb::password')
$influx_root_password = hiera('lma::collector::influxdb::root_password')

# Let's use alreadt defined params for ceilometer
include ::ceilometer::params
$ceilometer_service_name = $::ceilometer::params::api_service_name

# calculated values
$metering_connection = "stacklight://${influx_user}:${influx_password}@${influxdb_vip}:${influxdb_port}/ceilometer"
$resource_connection = "es://${elasticsearch_node}:${elasticsearch_port}"
$event_connection    = "es://${elasticsearch_node}:${elasticsearch_port}"
$connection = $metering_connection

# TODO validate values before proceed

ceilometer_config { 'database/metering_connection': value => "${metering_connection}" }
ceilometer_config { 'database/resource_connection': value => "${resource_connection}" }
ceilometer_config { 'database/event_connection': value => "${event_connection}" }
ceilometer_config { 'database/connection': value => "${connection}" }

service { 'ceilometer-service':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::api_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      tag        => 'ceilometer-service',
    }

Ceilometer_config<||> ~> Service['ceilometer-service']

