notice('MODULAR: fuel-plugin-telemetry: hiera-post_deployment.pp')

# TODO Hierra ignores this file
$hiera_file = '/etc/hiera/plugins/telemetry-post_deployment.yaml'


  $telemetry = hiera('telemetry')
  
  if $telemetry['influxdb_ip'] {
  
    notice('Use External InfluxDB')
  
    $influxdb_server  = $telemetry['influxdb_ip']
  
  } else {
  
    notice('Use StackLight integrated InfluxDB')
  
    if !hiera('influxdb_grafana',false) {
      fail('The StackLight InfluxDB-Grafana Plugin not found, please configure external InfluxDB in advanced settings or install the plugin')
    }
  
    $influxdb_grafana = hiera('influxdb_grafana')
  
    # influx ip
    prepare_network_config(hiera_hash('network_scheme', {}))
    $network_metadata = hiera_hash('network_metadata')
    $influxdb_nodes = get_nodes_hash_by_roles($network_metadata, ['influxdb_grafana', 'primary-influxdb_grafana'])
    $nodes_array = values($influxdb_nodes)
  
    if count($nodes_array)==0 {
      fail('No nodes with InfluxDB Grafana role, please add one or more nodes with this role to the environment or configure external InfluxDB in advanced settings')
    }
    # test for multiple inxlixdb nodes !!!
    $influxdb_server = $nodes_array[0]['network_roles']['management']
    #$influxdb_server = $influxdb_nodes[0]['internal_address']
   
  }



$calculated_content = inline_template('
---
telemetry::influxdb::server: <%= @influxdb_server %>

')


file { $hiera_file:
  ensure  => file,
  content => $calculated_content,
}
