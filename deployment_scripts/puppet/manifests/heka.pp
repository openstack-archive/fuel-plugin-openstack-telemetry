

$version = '0.10.0'
$hekad_max_message_size = 256 * 1024
$hekad_max_process_inject = 1
$hekad_max_timer_inject = 10
$poolsize = 100
$install_init_script = true
$config_dir = '/etc/ceilometer_collector'

amqp-openstack_sample.toml
decoder-sample.toml
encoder-influxdb.toml
encoder-resource-elasticsearch.toml
file-output-resource.toml
file-output.toml
filter-influxdb_accumulator_sample.toml
output-elasticsearch-resource.toml
output-influxdb-samples.toml


file {
    "${config_dir}/amqp-openstack_sample.toml":              content => template( 'telemetry/heka/amqp-openstack_sample.toml.erb' );
    "${config_dir}/decoder-sample.toml":                     content => template( 'telemetry/heka/decoder-sample.toml.erb' );
    "${config_dir}/encoder-influxdb.toml":                   content => template( 'telemetry/heka/encoder-influxdb.toml.erb' );
    "${config_dir}/encoder-resource-elasticsearch.toml":     content => template( 'telemetry/heka/encoder-resource-elasticsearch.toml.erb' );
    "${config_dir}/file-output-resource.toml":               content => template( 'telemetry/heka/file-output-resource.toml.erb' );
    "${config_dir}/file-output.toml":                        content => template( 'telemetry/heka/file-output.toml.erb' );
    "${config_dir}/filter-influxdb_accumulator_sample.toml": content => template( 'telemetry/heka/filter-influxdb_accumulator_sample.toml.erb' );
    "${config_dir}/output-elasticsearch-resource.toml":      content => template( 'telemetry/heka/output-elasticsearch-resource.toml.erb' );
    "${config_dir}/output-influxdb-samples.toml":            content => template( 'telemetry/heka/output-influxdb-samples.toml.erb' );
}



  ::heka { 'ceilometer_collector':
    config_dir          => '/etc/ceilometer_collector',
    user                => $user,
    #additional_groups   => $additional_groups,
    hostname            => $::hostname,
    max_message_size    => $hekad_max_message_size,
    max_process_inject  => $hekad_max_process_inject,
    max_timer_inject    => $hekad_max_timer_inject,
    poolsize            => $poolsize,
    install_init_script => $install_init_script,
    version             => $version,
  }