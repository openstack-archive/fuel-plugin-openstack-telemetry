notice('MODULAR: fuel-plugin-telemetry: influxdb-create-db.pp')

class { 'telemetry::create_influxdb_database': }
