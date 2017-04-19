.. _limitations:

Limitations
-----------

The OpenStack Telemetry plugin for Fuel has the following limitations:

* Ceilometer API is not fully supported by default. The following Ceilometer
  commands are supported:

  * By default:

    * ``ceilometer sample-list``
    * ``ceilometer statistics``

  * If the :guilabel:`Resource API` is enabled:

    * ``ceilometer resource-list``
    * ``ceilometer meter-list``

  * If the :guilabel:`Event API` is enabled:

    * ``ceilometer event-list``

  Ceilometer
  `complex queries <http://docs.openstack.org/developer/ceilometer/webapi/v2.html#complex-query>`_
  are not supported.

* The Telemetry plugin does not store all the OpenStack resources metadata
  along with the Ceilometer Samples. The default list is as follows:

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

  To use the Ceilometer API requests based on metadata, add the required
  metadata as described in :ref:`configure`.

* The coordination for Ceilometer central agent and Aodh alarm evaluator
  services is switched off if RabbitMQ is used. The Telemetry plugin is based
  on the Ceilometer used in Mirantis OpenStack. Therefore, the notification
  agents do not require coordination. The coordination through tooz with
  Zookeeper back end is supported if the Kafka plugin is installed.

* The OpenStack Telemetry plugin cannot be used if the
  `Redis plugin <https://github.com/openstack/fuel-plugin-ceilometer-redis>`_
  is already enabled in the environment.

* If telemetry-collector-hindsight service running as systemd service,
  there is no separate log file. The process of collecting logs is centralized.
  Way to get recent logs of `telemetry-collector-hindsight` service:
  | ``journalctl -u telemetry-collector-hindsight``
