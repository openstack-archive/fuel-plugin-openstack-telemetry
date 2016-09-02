notice('MODULAR: fuel-plugin-telemetry: influxdb-create-db.pp')

$influxdb_mode = hiera('telemetry::influxdb::mode')

if $influxdb_mode == 'local' {

  class { 'telemetry::create_influxdb_database': }

}
