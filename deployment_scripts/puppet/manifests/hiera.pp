notice('MODULAR: fuel-plugin-telemetry: hiera.pp')

$plugin_data = hiera_hash('telemetry', undef)
prepare_network_config(hiera_hash('network_scheme', {}))
$network_metadata = hiera_hash('network_metadata')


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

$hiera_file = '/etc/hiera/plugins/telemetry.yaml'

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
      #$monitor_elasticsearch = false
    }
    'local': {
      $es_vip_name = 'es_vip_mgmt'
      if $network_metadata['vips'][$es_vip_name] {
        $es_server = $network_metadata['vips'][$es_vip_name]['ipaddr']
        #$monitor_elasticsearch = true
      } elsif $es_nodes_count > 0 {
        $es_server = $es_nodes[0]['internal_address']
        #$monitor_elasticsearch = true
      } else {
        $es_server = undef
        #$monitor_elasticsearch = false
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


')


file { $hiera_file:
  ensure  => file,
  content => $calculated_content,
}
