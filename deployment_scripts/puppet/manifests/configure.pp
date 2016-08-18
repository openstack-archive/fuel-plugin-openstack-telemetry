notice('MODULAR: fuel-plugin-telemetry: configure.pp')

$packages = {
  'ceilometer-collector' => {
    # keep 'absent' instead of 'purged' for idempotence
    ensure => 'absent',
    require => Service["ceilometer-collector"],
  },
  'python-pip' => {
    ensure => 'present',
  },
  'influxdb' => {
    ensure => 'present',
    provider => 'pip',
    require => Package['python-pip'],
    # Not sure at a momment
    notify => Service['ceilometer-service']
  },
  'elasticsearch' => {
    ensure => 'present',
    provider => 'pip',
    require => Package['python-pip'],
    # Not sure at a momment
    notify => Service['ceilometer-service']
  },
}

# TODO: stop collector only when qeue is empty*
# *wait utill all the events went from collector
#  before stop collector service
# maybe service'collector' ensure stopped; require exec 'wait for qeue is empty'

create_resources(package, $packages)

# Stopn not needed any more service
service { 'ceilometer-collector':
    ensure     => stopped,
    enable     => false,
    hasstatus  => true,
}

# TODO_0 'set' default values when looking for via hiera
# TODO_1 add if statments in case of 'advanced settings' passed through Fuel UI
# TODO_2 checks if we can reach ES, influxdb before actioning?
$aodh_nodes           = hiera('aodh_nodes')
$elasticsearch_node   = hiera('lma::collector::elasticsearch::server')
$elasticsearch_port   = hiera('lma::collector::elasticsearch::rest_port')
$influxdb_vip         = hiera('lma::collector::influxdb::server')
$influxdb_port        = hiera('lma::collector::influxdb::port')
$influx_database      = hiera('lma::collector::influxdb::database')
$influx_user          = 'root'
$influx_password      = hiera('lma::collector::influxdb::password')
$influx_root_password = hiera('lma::collector::influxdb::root_password')

# Let's use already defined params for ceilometer
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

