
notice('MODULAR: fuel-plugin-telemetry: hindsight.pp')

$user              = 'hindsight'
$group             = 'hindsight'
$influxdb_address  = hiera('telemetry::influxdb::address')
$influxdb_port     = hiera('telemetry::influxdb::port')
$influxdb_database = hiera('telemetry::influxdb::database')
$influxdb_user     = hiera('telemetry::influxdb::user')
$influxdb_password = hiera('telemetry::influxdb::password')

#TODO kafka integration
$brokerlist = 'broker1:9092'

# Install packages

package { 'libluasandbox-dev': }
package { 'libluasandbox1': }
package { 'hindsight': }
package { 'librdkafka1': }
package { 'lua-sandbox-extensions': }

# User/group

user { $user:
  ensure => 'present',
  groups => $group,
}

group { $group:
  ensure => 'present',
}

# Config files

file {  '/etc/hindsight/hindsight.cfg':
  ensure  => 'present',
  owner   => $user,
  group   => $group,
  content => template( 'telemetry/hindsight/hindsight.cfg.erb' ),
  require => Package['hindsight']
}

file {  '/var/lib/hindsight':
  ensure  => 'directory',
  owner   => $user,
  group   => $group,
  recurse => true,
  require => Package['hindsight']
}

$run_dir='/var/lib/hindsight/run'

$dirs = [
  $run_dir,
  "${run_dir}/analysis",
  "${run_dir}/input",
  "${run_dir}/output",
]

file { $dirs:
  ensure  => 'directory',
  owner   => $user,
  group   => $group,
  recurse => true,
  require  => Package['hindsight']
}

$templates='telemetry/hindsight/'

file {
  "${run_dir}/analysis/influxdb_accumulator.cfg":
    content => template( "${templates}/analysis/influxdb_accumulator.cfg.erb"),
    owner   => $user,
    group   => $group;
  "${run_dir}/analysis/influxdb_accumulator.lua":
    content => template( "${templates}/analysis/influxdb_accumulator.lua.erb"),
    owner   => $user,
    group   => $group;
  "${run_dir}/output/influxdb_ceilometer.cfg":
    content => template( "${templates}/output/influxdb_ceilometer.cfg.erb"),
    owner   => $user,
    group   => $group;
  "${run_dir}/output/influxdb_tcp.lua":
    content => template( "${templates}/output/influxdb_tcp.lua.erb"),
    owner   => $user,
    group   => $group;
  "${run_dir}/input/ceilometer_kafka.cfg":
    content => template( "${templates}/input/ceilometer_kafka.cfg.erb"),
    owner   => $user,
    group   => $group;
  "${run_dir}/input/ceilometer_kafka.lua":
    content => template( "${templates}/input/ceilometer_kafka.lua.erb"),
    owner   => $user,
    group   => $group;
} ->
file { '/etc/init/hindsight.conf':
  content => template( "${templates}/init.conf.erb")
}

service { 'hindsight':
  ensure   => 'running',
  enable   => true,
  provider => 'upstart',
  require  => File['/etc/init/hindsight.conf']
}

# TODO move to separated manifest
#ceilometer_config { 'notification/messaging_urls':    value => ['http1','http2'] }