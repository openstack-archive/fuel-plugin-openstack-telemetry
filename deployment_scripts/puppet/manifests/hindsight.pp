
notice('MODULAR: fuel-plugin-telemetry: hindsight.pp')

$user              = 'hindsight'
$group             = 'hindsight'
$influxdb_address  = hiera('telemetry::influxdb::address')
$influxdb_port     = hiera('telemetry::influxdb::port')
$influxdb_database = hiera('telemetry::influxdb::database')
$influxdb_user     = hiera('telemetry::influxdb::user')
$influxdb_password = hiera('telemetry::influxdb::password')
# TDOD field in UI, add in hiera.pp
$metadata_fields   = hiera('telemetry::metadata_fields')

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

# Config files

file {  '/etc/telemetry_hindsight/hindsight.cfg':
  ensure  => 'present',
  owner   => $user,
  group   => $group,
  content => template( 'telemetry/hindsight/hindsight.cfg.erb' ),
  require => Package['hindsight']
}

file {  '/usr/share/telemetry_hindsight':
  ensure  => 'directory',
  owner   => $user,
  group   => $group,
  recurse => true,
  require => Package['hindsight']
}

$run_dir     = '/usr/share/telemetry_hindsight/run'
$modules_dir = '/usr/share/telemetry_lua_modules'
# parent /var/lib/hindsight?
$output_dir  = '/var/lib/hindsight/output'

$dirs = [
  $run_dir,
  
  
  "${run_dir}/analysis",
  "${run_dir}/input",
  "${run_dir}/output",
  $modules_dir,
  "${modules_dir}/common",
  "${modules_dir}/decoders",
  "${modules_dir}/encoders",
  "${modules_dir}/filters",
  $output_dir
]

file { $dirs:
  ensure  => 'directory',
  owner   => $user,
  group   => $group,
  recurse => true,
  require  => Package['hindsight']
}

$templates='telemetry/hindsight/'


$files_defaults = {
    owner  => $user,
    group  => $group;
    before => Service['hindsight']  
}

# Templates 

$configs = {
  "${run_dir}/output/influxdb_ceilometer.cfg": {
    content => template( "${templates}/output/influxdb_ceilometer.cfg.erb"),
  },
  "${run_dir}/input/ceilometer_kafka.cfg": {
    content => template( "${templates}/input/kafka_input.cfg.erb"),  
  }
}

create_resources(file, $configs, $files_defaults)

# Files

$scripts = {
  "${run_dir}/output/influxdb_tcp.lua": {
    source => 'puppet:///modules/telemetry/hindsight/run/output/influxdb_tcp.lua'
  },
  "${run_dir}/input/kafka_input.lua": {
    source => 'puppet:///modules/telemetry/hindsight/run/input/kafka_input.lua'
  },
  "${modules_dir}/common/ceilometer.lua": {
    source => 'puppet:///modules/telemetry/common/ceilometer.lua' 
  },
  "${modules_dir}/common/influx.lua": {
    source => 'puppet:///modules/telemetry/common/influx.lua'
  },
  "${modules_dir}/common/samples.lua": {
    source => 'puppet:///modules/telemetry/common/samples.lua' 
  },
  "${modules_dir}/decoders/metering.lua": {
    source => 'puppet:///modules/telemetry/common/metering.lua' 
  }
}

create_resources(file, $scripts, $files_defaults)

file { '/etc/init/hindsight.conf':
  content => template( "${templates}/init.conf.erb")
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