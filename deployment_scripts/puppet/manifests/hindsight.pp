
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
$topics            = 'metering.sample'
$modules_dir       = hiera('telemetry::lua::modules_dir')

if hiera('telemetry::elasticsearch::enabled') {
  $es_server = hiera('telemetry::elasticsearch::server')
  $es_port   = hiera('telemetry::elasticsearch::rest_port')
} else {
  $es_server = ''
  $es_port   = ''
}

# Kafka integration
$brokerlist = hiera('telemetry::kafka::nodes_list')
$kafka_port = hiera('telemetry::kafka::port')

# Install packages

package { 'libluasandbox-dev': }
package { 'libluasandbox1': }
package { 'hindsight': }
package { 'librdkafka1': }
package { 'lua-sandbox-extensions': }
package { 'python-oslo.messaging': }
package { 'python-pip': }

package { 'kafka-python':
  ensure   => '1.2.5',
  provider => 'pip'
}

# User/group

user { $user:
  ensure => 'present',
  groups => $group,
}

group { $group:
  ensure => 'present',
}

# Directories

$conf_dir      = '/etc/telemetry-collector-hindsight'
$hindsight_dir = '/usr/share/telemetry_hindsight'
$run_dir       = "${hindsight_dir}/run"
$output_dir    = '/var/lib/hindsight/output'
$sandbox_dir   = '/usr/lib/x86_64-linux-gnu/luasandbox'
$templates     = 'telemetry/hindsight/'


$dirs = [
  $conf_dir,
  $hindsight_dir,
  "${hindsight_dir}/load",
  "${hindsight_dir}/load/input",
  "${hindsight_dir}/load/output",
  "${hindsight_dir}/load/analysis",
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
  require => Package['hindsight'],
}

$files_defaults = {
  owner  => $user,
  group  => $group,
  before => Service['telemetry-collector-hindsight'],
  notify => Service['telemetry-collector-hindsight'],
}

# Config files

file {  "${conf_dir}/hindsight.cfg":
  ensure  => 'present',
  owner   => $user,
  group   => $group,
  content => template( 'telemetry/hindsight/hindsight.cfg.erb' ),
  require => Package['hindsight'],
  notify  => Service['telemetry-collector-hindsight'],
}

# Templates

$configs = {
  "${run_dir}/output/influxdb_ceilometer.cfg" => {
    content => template( "${templates}/output/influxdb_ceilometer.cfg.erb"),
  },
  "${run_dir}/output/elasticsearch_ceilometer.cfg" => {
    content => template( "${templates}/output/elasticsearch_ceilometer.cfg.erb"),
  },
  "${run_dir}/input/kafka_input.cfg" => {
    content => template( "${templates}/input/kafka_input.cfg.erb"),
  },
}

create_resources(file, $configs, $files_defaults)

# Files

$scripts = {
  "${run_dir}/output/influxdb_tcp.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/output/influxdb_tcp.lua'
  },
  "${run_dir}/input/kafka_input.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/input/kafka_input.lua'
  },
  "${run_dir}/output/elasticsearch_bulk_tcp.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/output/elasticsearch_bulk_tcp.lua'
  }
}

create_resources(file, $scripts, $files_defaults)

file { '/etc/init/telemetry-collector-hindsight.conf':
  content => template( "${templates}/init.conf.erb"),
  before  => Service['telemetry-collector-hindsight'],
}

service { 'telemetry-collector-hindsight':
  ensure   => 'running',
  enable   => true,
  provider => 'upstart',
  require  => File['/etc/init/telemetry-collector-hindsight.conf'],
}
