# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

class telemetry::create_influxdb_database () {

  notice('fuel-plugin-influxdb-grafana: influxdb_configuration.pp')

  $telemetry = hiera('telemetry')

  if $telemetry['influxdb_ip'] {

    notice('Use External InfluxDB')

    $influxdb_server  = $telemetry['influxdb_ip']
    $local_port       = $telemetry['influxdb_port']
    $admin_user       = $telemetry['influxdb_admin_user']
    $admin_password   = $telemetry['influxdb_admin_pass']
    $username         = $telemetry['influxdb_username']
    $password         = $telemetry['influxdb_userpass']
    $retention_period = 30

  } else {

    notice('Use StackLight integrated InfluxDB')

    if !hiera('influxdb_grafana',false) {
      fail('The StackLight InfluxDB-Grafana Plugin not found, please configure\
       external InfluxDB in advanced settings or install the plugin')
    }

    $influxdb_grafana = hiera('influxdb_grafana')

    # influx ip
    prepare_network_config(hiera_hash('network_scheme', {}))
    $network_metadata = hiera_hash('network_metadata')
    $influxdb_nodes = get_nodes_hash_by_roles($network_metadata, ['influxdb_grafana', 'primary-influxdb_grafana'])
    $nodes_array = values($influxdb_nodes)

    if count($nodes_array)==0 {
      fail('No nodes with InfluxDB Grafana role, please add one or more nodes with\
       this role to the environment or configure external InfluxDB in advanced settings')
    }
    # test for multiple inxlixdb nodes !!!
    $influxdb_server = $nodes_array[0]['network_roles']['management']
    #$influxdb_server = $influxdb_nodes[0]['internal_address']

    $local_port       = 8086
    $admin_user       = 'root'
    $admin_password   = $influxdb_grafana['influxdb_rootpass']
    $username         = $influxdb_grafana['influxdb_username']
    $password         = $influxdb_grafana['influxdb_userpass']
    $retention_period = $influxdb_grafana['retention_period']

  }

  $influxdb_url = "http://${influxdb_server}:${local_port}"
  $replication_factor = 3
  $database_name = 'ceilometer'

  telemetry::influxdb_database { $database_name:
    admin_user         => $admin_user,
    admin_password     => $admin_password,
    influxdb_url       => $influxdb_url,
    db_user            => $username,
    db_password        => $password,
    retention_period   => $retention_period,
    replication_factor => $replication_factor,
  }

}
