notice('MODULAR: fuel-plugin-telemetry: hiera.pp')

$plugin_data = hiera_hash('telemetry', undef)
prepare_network_config(hiera_hash('network_scheme', {}))
$network_metadata = hiera_hash('network_metadata')
$hiera_file = '/etc/hiera/plugins/telemetry.yaml'
$telemetry = hiera('telemetry')

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

# Elasticsearch

$is_elasticsearch_node = roles_include(['elasticsearch_kibana', 'primary-elasticsearch_kibana'])

if $plugin_data['elastic_search_ip'] {
  $elasticsearch_mode = 'remote'
} else {
  $elasticsearch_mode = 'local'
}

#$elasticsearch_mode = $plugin_data['elasticsearch_mode']
$es_nodes = get_nodes_hash_by_roles($network_metadata, ['elasticsearch_kibana', 'primary-elasticsearch_kibana'])
$es_nodes_count = count($es_nodes)

case $elasticsearch_mode {
  'remote': {
    $es_server = $plugin_data['elastic_search_ip']
  }
  'local': {
    $es_vip_name = 'es_vip_mgmt'
    if $network_metadata['vips'][$es_vip_name] {
      $es_server = $network_metadata['vips'][$es_vip_name]['ipaddr']
    } else {
      $es_server = undef
    }
  }
  default: {
    fail("'${elasticsearch_mode}' mode not supported for Elasticsearch")
  }
}
if $es_nodes_count > 0 or $es_server {
  $es_is_deployed = true
} else {
  $es_is_deployed = false
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

  # TODO test for multiple inxlixdb nodes !!!
  $influxdb_address = $nodes_array[0]['network_roles']['management']

  $retention_period  = $influxdb_grafana['retention_period']
  $influxdb_user     = $influxdb_grafana['influxdb_username']
  $influxdb_password = $influxdb_grafana['influxdb_userpass']
  $influxdb_port     = '8086'
  $influxdb_database = 'ceilometer'
  $influxdb_rootpass = $influxdb_grafana['influxdb_rootpass']

}

# Rabbit

$rabbit_info = hiera('rabbit')
$rabbit_password = $rabbit_info['password']
$rabbit_user = $rabbit_info['user']

# remove spaces from host list
$amqp_hosts = regsubst(hiera('amqp_hosts'),'\s','','G')
$amqp_url   = "amqp://${rabbit_user}:${rabbit_password}@${amqp_hosts}/"

$metadata_fields   = join(['status deleted container_format min_ram updated_at ',
  'min_disk is_public size checksum created_at disk_format protected instance_host ',
  'host  display_name instance_id instance_type status state'])

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

<% if @es_is_deployed -%>
telemetry::elasticsearch::server: <%= @es_server %>
telemetry::elasticsearch::rest_port: 9200
<% end -%>

telemetry::influxdb::mode: <%= @influxdb_mode %>
telemetry::influxdb::address: <%= @influxdb_address %>
telemetry::influxdb::port: <%= @influxdb_port %>
telemetry::influxdb::database: <%= @influxdb_database %>
telemetry::influxdb::user: <%= @influxdb_user %>
telemetry::influxdb::password: <%= @influxdb_password %>
telemetry::influxdb::retention_period: <%= @retention_period %>
telemetry::influxdb::rootpass: <%= @influxdb_rootpass %>

telemetry::heka::version: "0.10.0"
telemetry::heka::max_message_size: 262144
telemetry::heka::max_process_inject: 1
telemetry::heka::max_timer_inject: 10
telemetry::heka::poolsize: 100
telemetry::heka::config_dir: "/etc/telemetry-collector"

telemetry::rabbit::url: "<%= @amqp_url %>"

telemetry::metadata_fields: "<%= @metadata_fields %>"
telemetry::lua::modules_dir: "/usr/share/telemetry_lua_modules"

')

file { $hiera_file:
  ensure  => file,
  content => $calculated_content,
}
