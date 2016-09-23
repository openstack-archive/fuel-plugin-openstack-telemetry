notice('MODULAR: fuel-plugin-telemetry: hiera.pp')

$plugin_data      = hiera_hash('telemetry', undef)
$network_metadata = hiera_hash('network_metadata')
$hiera_file       = '/etc/hiera/plugins/telemetry.yaml'
$telemetry        = hiera('telemetry')
prepare_network_config(hiera_hash('network_scheme', {}))

# Ceilometer

$ceilometer_hash                       = hiera_hash('ceilometer', $default_ceilometer_hash)
$ceilometer_alarm_history_time_to_live = $ceilometer_hash['alarm_history_time_to_live']
$ceilometer_event_time_to_live         = $ceilometer_hash['event_time_to_live']
$ceilometer_metering_time_to_live      = $ceilometer_hash['metering_time_to_live']
$ceilometer_http_timeout               = $ceilometer_hash['http_timeout']
$ceilometer_notification_driver        = $ceilometer_hash['notification_driver']
$ceilometer_db_password                = $ceilometer_hash['db_password']
$ceilometer_enabled                    = true
$ceilometer_metering_secret            = $ceilometer_hash['metering_secret']
$ceilometer_user_password              = $ceilometer_hash['user_password']
$elasticsearch_script_inline           = 'on'
$elasticsearch_script_indexed          = 'on'
$elasticsearch_mode                    = $plugin_data['elasticsearch_mode']

# Elasticsearch
$es_vip_name           = 'es_vip_mgmt'

case $elasticsearch_mode {
  'remote': {
    $es_server = $plugin_data['elastic_search_ip']
    $es_port   = $plugin_data['elastic_search_port']
  }
  'local': {
    if $network_metadata['vips'][$es_vip_name] {
      $es_server = $network_metadata['vips'][$es_vip_name]['ipaddr']
      # TODO: use data from hiera for $es_port. Can't do it rigt now.
      $es_port   = '9200'
    } else {
      $es_server = ''
      $es_port   = '9200'
    }
  }
  default: {
    fail("'${elasticsearch_mode}' mode not supported for Elasticsearch")
  }
}

# InfluxDB

if $telemetry['influxdb_address'] {

  notice('Use external InfluxDB')

  $influxdb_mode = 'remote'

  $influxdb_address  = $telemetry['influxdb_address']
  $influxdb_port     = $telemetry['influxdb_port']
  $influxdb_database = $telemetry['influxdb_database']
  $influxdb_user     = $telemetry['influxdb_user']
  $influxdb_password = $telemetry['influxdb_password']

  # TODO hardcode or move to params?
  $retention_period = '30'

} else {

  notice('Use StackLight integrated InfluxDB')

  $influxdb_mode = 'local'

  if !hiera('influxdb_grafana',false) {
    fail(join([
      'The StackLight InfluxDB-Grafana Plugin not found, ',
      'please configure external InfluxDB in advanced settings or install the plugin'
    ]))
  }

  $influxdb_grafana = hiera('influxdb_grafana')
  $influxdb_nodes = get_nodes_hash_by_roles($network_metadata, ['influxdb_grafana', 'primary-influxdb_grafana'])
  $nodes_array = values($influxdb_nodes)

  if count($nodes_array)==0 {
    fail(join([
      'No nodes with InfluxDB Grafana role, please add one or more nodes',
      'with this role to the environment or configure external InfluxDB in advanced settings'
    ]))
  }

  $influxdb_vip_name = 'influxdb'
  if $network_metadata['vips'][$influxdb_vip_name] {
    $influxdb_address = $network_metadata['vips'][$influxdb_vip_name]['ipaddr']
  } else {
    $influxdb_address = $nodes_array[0]['network_roles']['management']
  }

  $retention_period  = $influxdb_grafana['retention_period']
  $influxdb_user     = $influxdb_grafana['influxdb_username']
  $influxdb_password = $influxdb_grafana['influxdb_userpass']
  $influxdb_port     = '8086'
  $influxdb_database = 'ceilometer'
  $influxdb_rootpass = $influxdb_grafana['influxdb_rootpass']

}

# Rabbit

$amqp_host       = get_network_role_property('management', 'ipaddr')
$amqp_port       = hiera('amqp_port')
$rabbit_info     = hiera('rabbit')
$rabbit_password = $rabbit_info['password']
$rabbit_user     = $rabbit_info['user']
$amqp_url        = "amqp://${rabbit_user}:${rabbit_password}@${amqp_host}:${amqp_port}/"

$metadata_fields   = join(['status deleted container_format min_ram updated_at ',
  'min_disk is_public size checksum created_at disk_format protected instance_host ',
  'host  display_name instance_id instance_type status state'])

# Kafka
$kafka_port     = 9092
$zookeeper_port = 2181
$kafka_nodes    = get_nodes_hash_by_roles($network_metadata, ['kafka', 'primary-kafka'])
$kafka_ip_map   = get_node_to_ipaddr_map_by_network_role($kafka_nodes, 'management')

if count($kafka_ip_map)>0 {
    notice('Kafka nodes found')
    $kafka_enabled      = true
    $kafka_ips          = sort(values($kafka_ip_map))
    # Format: host:port,host:port for ceiolmeter.conf
    $tmp_brokers_list   = join($kafka_ips,":${kafka_port},")
    $broker_list        = join([$tmp_brokers_list,":${kafka_port}"])
    $tmp_zookeeper_list = join($kafka_ips,":${zookeeper_port},")
    $zookeeper_list     = join([$tmp_zookeeper_list,":${zookeeper_port}"])
} else {
    notice('No Kafka nodes found')
    $kafka_enabled      = false
}

$calculated_content = inline_template('
---
ceilometer:
    alarm_history_time_to_live: "<%= @ceilometer_alarm_history_time_to_live %>"
    event_time_to_live: "<%= @ceilometer_event_time_to_live %>"
    metering_time_to_live: "<%= @ceilometer_metering_time_to_live %>"
    http_timeout: "<%= @ceilometer_http_timeout %>"
    notification_driver: "<%= @ceilometer_notification_driver %>"
    db_password: "<%= @ceilometer_db_password %>"
    enabled: "<%= @ceilometer_enabled %>"
    metering_secret: "<%= @ceilometer_metering_secret %>"
    user_password: "<%= @ceilometer_user_password %>"

# Required for StackLight LMA ElasticSearch params
lma::elasticsearch::script_inline: "<%= @elasticsearch_script_inline %>"
lma::elasticsearch::script_indexed: "<%= @elasticsearch_script_indexed %>"

# Elasticsearch

telemetry::elasticsearch::server: "<%= @es_server %>"
telemetry::elasticsearch::rest_port: "<%= @es_port %>"

# IndluxDB

telemetry::influxdb::mode: <%= @influxdb_mode %>
telemetry::influxdb::address: <%= @influxdb_address %>
telemetry::influxdb::port: <%= @influxdb_port %>
telemetry::influxdb::database: <%= @influxdb_database %>
telemetry::influxdb::user: <%= @influxdb_user %>
telemetry::influxdb::password: <%= @influxdb_password %>
telemetry::influxdb::retention_period: <%= @retention_period %>
telemetry::influxdb::rootpass: <%= @influxdb_rootpass %>

# Heka

telemetry::heka::version: "0.10.0"
telemetry::heka::max_message_size: 262144
telemetry::heka::max_process_inject: 1
telemetry::heka::max_timer_inject: 10
telemetry::heka::poolsize: 100
telemetry::heka::config_dir: "/etc/telemetry-collector-heka"

# Kafka

<% if @kafka_enabled -%>
telemetry::kafka::broker_list: "<%= @broker_list %>"
telemetry::kafka::nodes_list:
<% @kafka_ips.each do |s| -%>
  - "<%= s %>"
<% end -%>
telemetry::kafka::zookeeper_list: "<%= @zookeeper_list %>"
<% end -%>
telemetry::kafka::enabled: <%= @kafka_enabled %>
telemetry::kafka::port: <%= @kafka_port %>

telemetry::rabbit::url: "<%= @amqp_url %>"

telemetry::metadata_fields: "<%= @metadata_fields %>"
telemetry::lua::modules_dir: "/usr/share/telemetry_lua_modules"

')

file { $hiera_file:
  ensure  => file,
  content => $calculated_content,
}
