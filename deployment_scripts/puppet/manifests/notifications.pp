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

notice('fuel-plugin-openstack-telemetry: notifications.pp')

$ceilometer           = hiera_hash('ceilometer', {})
$rabbit               = hiera_hash('rabbit')
$storage_options      = hiera_hash('storage', {})
$murano               = hiera_hash('murano')
$sahara               = hiera_hash('sahara')
$telemetry            = hiera_hash('telemetry', {})
$influxdb_grafana     = hiera_hash('influxdb_grafana', false)
$elasticsearch_kibana = hiera_hash('elasticsearch_kibana', false)

$telemetry_enabled = $telemetry['metadata']['enabled']
if $influxdb_grafana {
  $influxdb_grafana_enabled = $influxdb_grafana['metadata']['enabled']
}
else{
  $influxdb_grafana_enabled = false
}

if $elasticsearch_kibana {
  $elasticsearch_kibana_enabled = $elasticsearch_kibana['metadata']['enabled']
}
else{
  $elasticsearch_kibana_enabled = false
}

if ($ceilometer['enabled'] or $telemetry_enabled) and ($influxdb_grafana_enabled or $elasticsearch_kibana_enabled){
  $notification_topics = ['notifications, lma_notifications']
}

else {
  $notification_topics = ['lma_notifications']
}

## Make sure the Log and Metric collector services are configured with the
## "pacemaker" provider
#Service<| title == 'log_collector' |> {
#  provider => 'pacemaker'
#}
#Service<| title == 'metric_collector' |> {
#  provider => 'pacemaker'
#}

# OpenStack logs and notifications are useful for deriving metrics, so we enable
# them even if Elasticsearch is disabled.
  # Sahara notifications
  if $sahara['enabled'] {
    include sahara::params
    $sahara_api_service    = $::sahara::params::api_service_name
    $sahara_engine_service = $::sahara::params::engine_service_name

    sahara_config { 'DEFAULT/enable_notifications':
      value  => true,
      notify => Service[$sahara_api_service, $sahara_engine_service],
    }
    sahara_config { 'DEFAULT/notification_topics':
      value  => $notification_topics,
      notify => Service[$sahara_api_service, $sahara_engine_service],
    }
    sahara_config { 'DEFAULT/notification_driver':
      value  => 'messaging',
      notify => Service[$sahara_api_service, $sahara_engine_service],
    }

    service { [$sahara_api_service, $sahara_engine_service]:
      hasstatus  => true,
      hasrestart => true,
    }
  }

  # Nova notifications
  include nova::params
  $nova_api_service       = $::nova::params::api_service_name
  $nova_conductor_service = $::nova::params::conductor_service_name
  $nova_scheduler_service = $::nova::params::scheduler_service_name

  nova_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Service[$nova_api_service, $nova_conductor_service, $nova_scheduler_service],
  }
  nova_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Service[$nova_api_service, $nova_conductor_service, $nova_scheduler_service],
  }
  nova_config { 'DEFAULT/notify_on_state_change':
    value  => 'vm_and_task_state',
    notify => Service[$nova_api_service, $nova_conductor_service, $nova_scheduler_service],
  }

  service { [$nova_api_service, $nova_conductor_service, $nova_scheduler_service]:
    hasstatus  => true,
    hasrestart => true,
  }

  # Cinder notifications
  include cinder::params
  $cinder_api_service       = $::cinder::params::api_service
  $cinder_scheduler_service = $::cinder::params::scheduler_service
  $cinder_volume_service    = $::cinder::params::volume_service

  if $storage_options['volumes_ceph'] {
    # In this case, cinder-volume runs on controller node
    $cinder_services = [$cinder_api_service, $cinder_scheduler_service, $cinder_volume_service]
  } else {
    $cinder_services = [$cinder_api_service, $cinder_scheduler_service]
  }

  cinder_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Service[$cinder_services],
  }
  cinder_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Service[$cinder_services],
  }

  service { $cinder_services:
    hasstatus  => true,
    hasrestart => true,
  }

  # Keystone notifications
  # Keystone is executed as a WSGI application inside Apache so the Apache
  # service needs to be restarted if necessary
  include apache::params
  include apache::service

  keystone_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Class['apache::service'],
  }
  keystone_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Class['apache::service'],
  }

  # Neutron notifications
  include neutron::params

  neutron_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Service[$::neutron::params::server_service],
  }
  neutron_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Service[$::neutron::params::server_service],
  }

  service { $::neutron::params::server_service:
    hasstatus  => true,
    hasrestart => true,
  }

  # Glance notifications
  include glance::params

  $glance_api_service = $::glance::params::api_service_name
  $glance_registry_service = $::glance::params::registry_service_name

  # Default value is 'image.localhost' for Glance
  $glance_publisher_id = "image.${::hostname}"

  glance_api_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Service[$glance_api_service],
  }
  glance_api_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Service[$glance_api_service],
  }
  glance_api_config { 'DEFAULT/default_publisher_id':
    value  => $glance_publisher_id,
    notify => Service[$glance_api_service],
  }
  glance_registry_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Service[$glance_registry_service],
  }
  glance_registry_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Service[$glance_registry_service],
  }
  glance_registry_config { 'DEFAULT/default_publisher_id':
    value  => $glance_publisher_id,
    notify => Service[$glance_registry_service],
  }

  service { [$glance_api_service, $glance_registry_service]:
    hasstatus  => true,
    hasrestart => true,
  }

  # Heat notifications
  include heat::params

  $heat_api_service    = $::heat::params::api_service_name
  $heat_engine_service = $::heat::params::engine_service_name

  heat_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Service[$heat_api_service, $heat_engine_service],
  }
  heat_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Service[$heat_api_service, $heat_engine_service],
  }

  service { $heat_api_service:
    hasstatus  => true,
    hasrestart => true,
  }

  # In MOS >=10 heat-engine isn't managed by pacemaker LP #1673074
  service { $heat_engine_service:
    hasstatus  => true,
    hasrestart => true,
  }

