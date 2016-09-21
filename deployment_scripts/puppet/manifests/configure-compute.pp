
notice('MODULAR: fuel-plugin-telemetry: configure-compute.pp')

if hiera('telemetry::kafka::enabled') {

  $kafka_ips  = hiera('telemetry::kafka::broker_list')
  $kafka_url  = "moskafka://${kafka_ips}"
  ceilometer_config {
    'oslo_messaging_notifications/transport_url': value => $kafka_url;
    'oslo_messaging_kafka/consumer_group':        value => 'ceilometer';
    'DEFAULT/transport_url':                      value => $kafka_url;
  } ~>
  service { 'ceilometer-polling':}

}