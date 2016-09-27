.. _limitations:

Limitations
-----------

The OpenStack Telemetry plugin for Fuel has the following limitations:

* Ceilometer API is not fully supported by default. The following Ceilometer
  commands are supported:
  
  * By default:

    * ``ceilometer sample-list``
    * ``ceilometer statistics``

  * If :guilabel:`Resource API` is enabled:

    * ``ceilometer resource-list``
    * ``ceilometer meter-list``

  * If :guilabel:`Event API` is enabled:

    * ``ceilometer event-list``

  Ceilometer
  `complex queries <http://docs.openstack.org/developer/ceilometer/webapi/v2.html#complex-query>`_
  are not supported.

* The Telemetry plugin does not store all the OpenStack resources metadata
  along with Ceilometer Samples in InfluxDB. Using the Fuel web UI, you can
  configure the list of metadata. The default values are as follows:

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

  To use Ceilometer API requests based on metadata, add the required metadata
  as described in :ref:`configure`.

* Coordination for Ceilometer central agent and Aodh alarm evaluator services
  are switched off if RabbitMQ is used. The Telemetry plugin is based on
  the Ceilometer used in Mirantis OpenStack. Therefore, the notification
  agents do not require coordination <see release notes? TODO>. The
  coordination through tooz with Zookeeper back end is supported if the Kafka
  plugin is installed.

* The OpenStack Telemetry plugin is incompatible with the Redis plugin
  <TODO: add the link here>.