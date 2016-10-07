
notice('MODULAR: fuel-plugin-telemetry: configure-compute.pp')

service { 'ceilometer-polling':}

if hiera('telemetry::kafka::enabled') {

  package { 'python-kafka':
    ensure => '1.2.5-1~u14.04+mos1'
  } ->
  package { 'python-oslo.messaging.kafka': }

  $kafka_ips  = hiera('telemetry::kafka::broker_list')
  $kafka_url  = "moskafka://${kafka_ips}"
  ceilometer_config {
    'oslo_messaging_notifications/transport_url': value => $kafka_url;
    'oslo_messaging_kafka/consumer_group':        value => 'ceilometer';
    'DEFAULT/transport_url':                      value => $kafka_url;
    'DEFAULT/shuffle_time_before_polling_task':   value => 300;
    'compute/resource_update_interval':           value => 600;
  }

  Ceilometer_config<||> ~> Service['ceilometer-polling']
}

exec { 'fix polling interval':
  command => '/bin/sed -i \'s/interval: 600/interval: 60/g\' /etc/ceilometer/pipeline.yaml',
  notify  => Service['ceilometer-polling'],
}
