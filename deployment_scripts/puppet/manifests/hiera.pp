notice('MODULAR: fuel-plugin-telemetry: hiera.pp')

$fuel_version = 0 + hiera('fuel_version')

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

$hiera_file = '/etc/hiera/plugins/telemetry.yaml'


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
')


file { $hiera_file:
  ensure  => file,
  content => $calculated_content,
}
