
notice('MODULAR: fuel-plugin-telemetry: heka.pp')

if !hiera('telemetry::kafka::enabled') {

  ## Get values

  $config_dir      = hiera('telemetry::heka::config_dir')
  $amqp_url        = hiera('telemetry::rabbit::url')
  $metadata_fields = hiera('telemetry::metadata_fields')


  if hiera('telemetry::elasticsearch::server',false) {
    $ip = hiera('telemetry::elasticsearch::server')
    $port = hiera('telemetry::elasticsearch::server')
    $elasticsearch_url = "http://${ip}:${port}"
  } else {
    #no Elasticsearch
    #heka failed to start if url schemma is not valid, so we set http here
    $elasticsearch_url = 'http://'
  }

  $influxdb_address  = hiera('telemetry::influxdb::address')
  $influxdb_port     = hiera('telemetry::influxdb::port')
  $influxdb_database = hiera('telemetry::influxdb::database')
  $influxdb_user     = hiera('telemetry::influxdb::user')
  $influxdb_password = hiera('telemetry::influxdb::password')

  $modules_dir       = hiera('telemetry::lua::modules_dir')

  ### Heka configuration

  File {
    before => Service['telemetry-collector']
  }

  file {
    "${config_dir}/amqp-openstack_sample.toml":              content => template( 'telemetry/heka/amqp-openstack_sample.toml.erb' );
    "${config_dir}/decoder-sample.toml":                     content => template( 'telemetry/heka/decoder-sample.toml.erb' );
    "${config_dir}/encoder-influxdb.toml":                   content => template( 'telemetry/heka/encoder-influxdb.toml.erb' );
    "${config_dir}/encoder-resource-elasticsearch.toml":     content => template( 'telemetry/heka/encoder-resource-elasticsearch.toml.erb' );
    "${config_dir}/file-output-resource.toml":               content => template( 'telemetry/heka/file-output-resource.toml.erb' );
    "${config_dir}/file-output.toml":                        content => template( 'telemetry/heka/file-output.toml.erb' );
    "${config_dir}/filter-influxdb_accumulator_sample.toml": content => template( 'telemetry/heka/filter-influxdb_accumulator_sample.toml.erb' );
    # TODO disable config when Elasticsearch not in use
    "${config_dir}/output-elasticsearch-resource.toml":      content => template( 'telemetry/heka/output-elasticsearch-resource.toml.erb' );
    "${config_dir}/output-influxdb-samples.toml":            content => template( 'telemetry/heka/output-influxdb-samples.toml.erb' );
  }

  # Heka Installation

  $version            = hiera('telemetry::heka::version')
  $max_message_size   = hiera('telemetry::heka::max_message_size')
  $max_process_inject = hiera('telemetry::heka::max_process_inject')
  $max_timer_inject   = hiera('telemetry::heka::max_timer_inject')
  $poolsize           = hiera('telemetry::heka::poolsize')

  # TODO we dont't need them on controller
  $install_init_script = false

  # Workaround for heka module
  # to prevent changing home of root user
  $user='root'
  user { $user: }

  ::heka { 'telemetry-collector':
    config_dir          => '/etc/telemetry-collector',
    user                => $user,
    #additional_groups   => $additional_groups,
    hostname            => $::hostname,
    max_message_size    => $max_message_size,
    max_process_inject  => $max_process_inject,
    max_timer_inject    => $max_timer_inject,
    poolsize            => $poolsize,
    install_init_script => $install_init_script,
    version             => $version,
  }

  # Heka pacemaker config

  pacemaker::service { 'telemetry-collector':
    ensure           => present,
    prefix           => false,
    primitive_class  => 'ocf',
    primitive_type   => 'ocf-telemetry',
    use_handler      => false,
    complex_type     => 'clone',
    complex_metadata => {
      # the resource should start as soon as the dependent resources
      # (eg RabbitMQ) are running *locally*
      'interleave' => true,
    },
    metadata         => {
      # Make sure that Pacemaker tries to restart the resource if it fails
      # too many times
      'failure-timeout'     => '120s',
      'migration-threshold' => '3',
    },
    parameters       => {
      'service_name' => 'telemetry-collector',
      'config'       => '/etc/telemetry-collector',
      'log_file'     => '/var/log/telemetry-collector.log',
      'user'         => $user,
    },
    operations       => {
      'monitor' => {
        'interval' => '20',
        'timeout'  => '10',
      },
      'start'   => {
        'timeout' => '30',
      },
      'stop'    => {
        'timeout' => '30',
      },
    },
  }

  service { 'telemetry-collector':
    ensure   => 'running',
    enable   => true,
    provider => 'pacemaker',
  }

}
