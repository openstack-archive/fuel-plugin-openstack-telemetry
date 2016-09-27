.. _limitations:

Limitations
-----------

The OpenStack Telemetry plugin for Fuel has the following limitations:

* It does not store all the OpenStack resources metadata along with Ceilometer
  Samples in InfluxDB. Using the Fuel web UI, you can configure the list of
  metadata. The default values are as follows:

  | ``status``
  | ``deleted``
  | ``container_format``
  | ``min_ram``
  | ``updated_at``
  | ``min_disk``
  | ``is_public size``
  | ``checksum``
  | ``created_at disk_format``
  | ``protected``
  | ``instance_host``
  | ``host``
  | ``display_name``
  | ``instance_id``
  | ``instance_type``
  | ``status``
  | ``state``
  | ``user_metadata.stack``

  To use Ceilometer API requests based on metadata, use the Fuel web UI to add
  the required metadata.

* Coordination for Ceilometer central agent and Aodh alarm evaluator services
  are switched off if RabbitMQ is used. The Telemetry plugin is based on
  the Ceilometer used in Mirantis OpenStack. Therefore, the notification
  agents do not require coordination <see release notes? TODO>. The
  coordination through tooz with Zookeeper back end is supported if the Kafka
  plugin is installed.

* The OpenStack Telemetry plugin is incompatible with the Redis plugin
  <TODO: add the link here>.