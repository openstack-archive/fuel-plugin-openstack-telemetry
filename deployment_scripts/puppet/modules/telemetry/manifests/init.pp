#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# == Class: telemetry
#
# Install and configure the core of the Heka service.
#
# === Parameters
#
# [*event_pipeline_file*]
#   TODO
#
# [*publishers*]
#   TODO
#
#
# === Examples (TODO)
#
# class { 'telemetry':
#   event_pipeline_file => $event_pipeline_file,
#   publishers          => $ceilometer_publishers,
# }
#
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#


class telemetry (
  $event_pipeline_file,
  $publishers,
) {

  file { $event_pipeline_file:
    ensure  => 'present',
    content => template('telemetry/event_pipeline.yaml.erb')
  }

}
