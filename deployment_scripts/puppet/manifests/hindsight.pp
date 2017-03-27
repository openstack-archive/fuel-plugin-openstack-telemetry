
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

if hiera('telemetry::elasticsearch::server', false) {
  $es_server = hiera('telemetry::elasticsearch::server')
} else {
  $es_server = ''
}

if hiera('telemetry::elasticsearch::rest_port', false) {
  $es_port = hiera('telemetry::elasticsearch::rest_port')
} else {
  $es_port = ''
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
package { 'python-kafka':
  ensure => '1.2.5-1~u14.04+mos1'
} ->
package { 'python-oslo.messaging.kafka': }

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
  "${run_dir}/input/kafka_input_1.cfg" => {
    content => template( "${templates}/input/kafka_input.cfg.erb"),
  },
  "${run_dir}/input/kafka_input_2.cfg" => {
    content => template( "${templates}/input/kafka_input.cfg.erb"),
  },
  "${run_dir}/input/kafka_input_3.cfg" => {
    content => template( "${templates}/input/kafka_input.cfg.erb"),
  },
}

create_resources(file, $configs, $files_defaults)

# Files
file { "${run_dir}/input/prune_input.lua":
  ensure => 'link',
  target => '/usr/share/luasandbox/sandboxes/heka/input/prune_input.lua',
}

$scripts = {
  "${run_dir}/output/influxdb_tcp.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/output/influxdb_tcp.lua'
  },
  "${run_dir}/input/kafka_input.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/input/kafka_input.lua'
  },
  "${run_dir}/output/elasticsearch_bulk_tcp.lua" => {
    source => 'puppet:///modules/telemetry/hindsight/run/output/elasticsearch_bulk_tcp.lua'
  },
  "${run_dir}/input/prune_input.cfg" => {
    source => 'puppet:///modules/telemetry/hindsight/run/input/prune_input.cfg',
  },
}

create_resources(file, $scripts, $files_defaults)

if $::operatingsystem == 'Ubuntu' {
  if versioncmp($::operatingsystemmajrelease, '16') >= 0 {

    $hindsight_provider = 'systemd'

    file { 'hindsight-service-unit':
      ensure  => present,
      path    => '/lib/systemd/system/telemetry-collector-hindsight.service',
      mode    => '0644',
      content => template("${templates}/hindsight.unit.erb"),
    }

    exec { 'systemctl-daemon-reload':
      command     => 'systemctl daemon-reload',
      refreshonly => true,
      path        => $::path,
    }

    File['hindsight-service-unit'] ~> Exec['systemctl-daemon-reload'] -> Service['telemetry-collector-hindsight']
  } else {

    $hindsight_provider = 'upstart'

    file { '/etc/init/telemetry-collector-hindsight.conf':
      content => template( "${templates}/init.conf.erb"),
    }

    File['/etc/init/telemetry-collector-hindsight.conf'] ~> Service['telemetry-collector-hindsight']
  }
} else {
  $hindsight_provider = undef
}

service { 'telemetry-collector-hindsight':
  ensure   => 'running',
  enable   => true,
  provider => $hindsight_provider,
}

