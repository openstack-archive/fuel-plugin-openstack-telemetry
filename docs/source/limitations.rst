.. _limitations:

Limitations
-----------

The OpenStack Telemetry plugin for Fuel has the following limitations:

* It doesn't store all the OpenStack resources metadata along with Ceilometer Samples in InfluxDB.
  The list of metadata is configurable on UI. The dafault values are:
status
deleted
container_format
min_ram
updated_at
min_disk
is_public size
checksum
created_at disk_format
protected
instance_host
host
display_name
instance_id
instance_type
status
state
user_metadata.stack

If you consider to use Ceilometer API requests based on metadata, please add the metadata you're interested in on UI.

* Coordination for Ceilometer central agent and Aodh alarm evaluator services are switched off if
  RabbitMQ is used. Note that the Telemetry plugin is based on Ceilometer MOS, i.e. the notification agents
  doesn't require coordination <see release notes? TODO>. The coordination through tooz with Zookeeper backend
  will be automatically supported if the Kafka plugin is installed.

* The OpenStack Telemetry plugin is incompatible with the Redis plugin <TODO: add the link here>
