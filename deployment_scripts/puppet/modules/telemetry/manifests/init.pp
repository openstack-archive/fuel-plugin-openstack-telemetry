class telemetry (
  $event_pipeline_file,
  $publishers,
) {

  file { "${event_pipeline_file}":
    ensure => 'present',
    content => template('telemetry/event_pipeline.yaml.erb')
  }

}
