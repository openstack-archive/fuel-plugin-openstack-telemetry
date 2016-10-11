.. _intro:

Introduction
------------

The OpenStack Telemetry plugin collects metrics about OpenStack resources and
provides this data through the Ceilometer API. By default, the plugin supports
only sample and statistics API. However, you can enable full Ceilometer API
support. The OpenStack Telemetry plugin implements all the Ceilometer
functionality except complex queries with InfluxDB and Elasticsearch as back
ends for samples and events.

The OpenStack Telemetry plugin uses the following Ceilometer components:

* Polling agents (both central and computes)
* Notification agent
* Ceilometer API agent

Ceilometer collector is not used. Instead, the Telemetry plugin uses its own
tools to collect telemetry data from the Ceilometer agents.

The Telemetry plugin provides a better functionality if deployed together
with the Kafka plugin. In this case, the Telemetry plugin configures Kafka as
a message bus for the Ceilometer agents and OpenStack services still send
notifications to RabbitMQ. To process this correctly, the Ceilometer
notification agent listens to Kafka and RabbitMQ simultaneously.
However, the Telemetry plugin works without Kafka as well, but there are some
scalability limitations. For more information, see :ref:`limitations`.

Depending on the message broker installed, Hindsight or Heka are used as
collectors:

* Hindsight -- fetches Ceilometer samples from Kafka and is installed on the
  same nodes as Kafka.
* Heka -- works with RabbitMQ and is installed on controller nodes under
  Pacemaker.

We recommend installing the Telemetry plugin along with the StackLight plugins.
In this case, the Telemetry plugin will use the same databases as StackLight:
InfluxDB and Elasticsearch. Otherwise, you can configure external storages.

.. seealso::

   * :ref:`architecture`