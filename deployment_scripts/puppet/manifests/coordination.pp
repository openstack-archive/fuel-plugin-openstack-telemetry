
notice('MODULAR: fuel-plugin-telemetry: coordination.pp')

if hiera('telemetry::kafka::enabled') {

  include ceilometer::params
  include aodh::params
  
  $metadata = {
    'resource-stickiness' => '1',
  }
  
  $operations = {
    'monitor'  => {
      'interval' => '20',
      'timeout'  => '10',
    },
    'start'    => {
      'timeout'  => '360',
    },
    'stop'     => {
      'timeout'  => '360',
    },
  }
  
  service { 'ceilometer-agent-central':
    ensure     => 'running',
    name       => $::ceilometer::params::agent_central_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
   }
  
  service { 'aodh-evaluator':
    ensure     => 'running',
    name       => $::aodh::params::evaluator_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
  
  
  pacemaker::service { $::ceilometer::params::agent_central_service_name :
    complex_type     => 'clone',
    complex_metadata => { 'interleave' => true },
    primitive_type   => 'ceilometer-agent-central',
    metadata         => $metadata,
    parameters       => { 'user' => 'ceilometer' },
    operations       => $operations,
  }
  
  pacemaker::service { $::aodh::params::evaluator_service_name :
    complex_type     => 'clone',
    complex_metadata => { 'interleave' => true },
    primitive_type   => 'aodh-evaluator',
    metadata         => $metadata,
    parameters       => { 'user' => 'aodh' },
    operations       => $operations,
  }
  
  # During deploy of plugin we need to update resource type from simple to
  # clone, but this is not working with current implementation of pcmk_resource
  # type (https://bugs.launchpad.net/fuel/+bug/1580660), that's why we need a
  # workaround below, this dirty workaround should be removed once
  # https://bugs.launchpad.net/fuel/+bug/1580660 is fixed.
  $old_ceilometer_primitive_exists=inline_template("<%= `if pcs resource show | grep -q '^ p_ceilometer-agent-central'; then /bin/echo true; fi;`%>")
  $old_aodh_primitive_exists=inline_template("<%= `if pcs resource show | grep -q '^ p_aodh-evaluator'; then /bin/echo true; fi;`%>")
  
  if $old_ceilometer_primitive_exists {
  
    notify { "Ceilometer agent central simple primitive exists and will be removed": }
  
    exec { 'remove_old_resource_central_agent':
      path    => '/usr/sbin:/usr/bin:/sbin:/bin',
      command => 'pcs resource delete p_ceilometer-agent-central --wait=120',
    }
    Exec['remove_old_resource_central_agent'] ->
    Pacemaker::Service["$::ceilometer::params::agent_central_service_name"]
  
  }
  
  if $old_aodh_primitive_exists {
  
    notify { "Aodh evaluator simple primitive exists and will be removed": }
  
    exec { 'remove_old_resource_aodh_evaluator':
      path    => '/usr/sbin:/usr/bin:/sbin:/bin',
      command => 'pcs resource delete p_aodh-evaluator --wait=120',
    }
    Exec['remove_old_resource_aodh_evaluator'] ->
    Pacemaker::Service["$::aodh::params::evaluator_service_name"]
  }
  
  Ceilometer_config <||> ~> Service["$::ceilometer::params::agent_central_service_name"]
  Aodh_config <||> ~> Service["$::aodh::params::evaluator_service_name"]
  Ceilometer_config <||> ~> Service['ceilometer-agent-notification']

}
