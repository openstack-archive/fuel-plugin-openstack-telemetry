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

  $influxdb_address   = hiera('telemetry::influxdb::address')
  $influxdb_port      = hiera('telemetry::influxdb::port')
  $influxdb_database  = hiera('telemetry::influxdb::database')
  $influxdb_user      = hiera('telemetry::influxdb::user')
  $influxdb_password  = hiera('telemetry::influxdb::password')
  $retention_period   = hiera('telemetry::influxdb::retention_period')
  $admin_user         = 'root'
  $admin_password     = hiera('telemetry::influxdb::rootpass')
  $influxdb_url       = "http://${influxdb_address}:${influxdb_port}"
  $replication_factor = 3
 
  telemetry::influxdb_database { $influxdb_database:
    admin_user         => $admin_user,
    admin_password     => $admin_password,
    influxdb_url       => $influxdb_url,
    db_user            => $influxdb_user,
    db_password        => $influxdb_password,
    retention_period   => $retention_period,
    replication_factor => $replication_factor,
  }

}
