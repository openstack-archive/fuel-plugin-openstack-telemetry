
notice('MODULAR: fuel-plugin-telemetry: hindsight.pp')

$plugin_data       = hiera_hash('telemetry', undef)
$resource_api      = $plugin_data['resource_api']
$user              = 'hindsight'
$group             = 'hindsight'
$influxdb_address  = hiera('telemetry::influxdb::address')
$influxdb_port     = hiera('telemetry::influxdb::port')
$influxdb_database = hiera('telemetry::influxdb::database')
$influxdb_user     = hiera('telemetry::influxdb::user')
$influxdb_password = hiera('telemetry::influxdb::password')
$metadata_fields   = hiera('telemetry::metadata_fields')
# TODO settings/hiera
$topics            = 'metering.sample'

#TODO kafka integration
$brokerlist = '"broker1:9092"'

# Install packages

package { 'libluasandbox-dev': }
package { 'libluasandbox1': }
package { 'hindsight': }
package { 'librdkafka1': }
package { 'lua-sandbox-extensions': }
package { 'python-oslo.messaging': }

# User/group

user { $user:
  ensure => 'present',
  groups => $group,
}

group { $group:
  ensure => 'present',
}

# Directories

$conf_dir      = '/etc/telemetry_hindsight'
$hindsight_dir = '/usr/share/telemetry_hindsight'
$run_dir       = "${hindsight_dir}/run"
# parent /var/lib/hindsight?
$output_dir    = '/var/lib/hindsight/output'
$sandbox_dir   = '/usr/lib/x86_64-linux-gnu/luasandbox'
$templates     = 'telemetry/hindsight/'


$dirs = [
  $conf_dir,
  $hindsight_dir,
  $run_dir,
  "${run_dir}/analysis",
  "${run_dir}/input",
  "${run_dir}/output",
  $output_dir
]

file { $dirs:
  ensure  => 'directory',
  owner   => $user,
  group   => $group,
  recurse => true,
  require => Package['hindsight']
}

$files_defaults = {
    owner  => $user,
    group  => $group,
    before => Service['hindsight']
}

# Config files

file {  '/etc/telemetry_hindsight/hindsight.cfg':
  ensure  => 'present',
  owner   => $user,
  group   => $group,
  content => template( 'telemetry/hindsight/hindsight.cfg.erb' ),
  require => Package['hindsight']
}

# Templates

$configs = {
  "${run_dir}/output/influxdb_ceilometer.cfg" => {
    content => template( "${templates}/output/influxdb_ceilometer.cfg.erb"),
  },
  "${run_dir}/input/ceilometer_kafka.cfg" => {
    content => template( "${templates}/input/kafka_input.cfg.erb"),
  }
}

create_resources(file, $configs, $files_defaults)

# Files

$scripts = {
  "${run_dir}/output/influxdb_tcp.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/output/influxdb_tcp.lua'
  },
  "${run_dir}/input/kafka_input.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/input/kafka_input.lua'
  }
}

create_resources(file, $scripts, $files_defaults)

file { '/etc/init/hindsight.conf':
  content => template( "${templates}/init.conf.erb"),
  before  => Service['hindsight']
}

service { 'hindsight':
  ensure   => 'running',
  enable   => true,
  provider => 'upstart',
  require  => File['/etc/init/hindsight.conf']
}

# TODO move to separated manifest
#ceilometer_config { 'notification/messaging_urls':    value => ['http1','http2'] }
