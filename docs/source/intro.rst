.. _intro:

Introduction
------------

The OpenStack Telemetry plugin collects metrics about OpenStack resources and provides this data through
Ceilometer API. This plugin implements all Ceilometer functionality with InfluxDB and
Elasticsearch as backends for metrics and events.

The following Ceilometer components are used as parts of the Telemetry plugin:
1. Polling agents (both central and computes)
2. Notification agent
3. API

Ceilometer collector is not used. The Telemetry plugin uses its own tools to collect metering
data from the Ceilometer agents.

The OpenStack Telemetry plugin does its best if it is deployed together with the Kafka plugin. In this case,
the Telemetry plugin configures Kafka as a message bus for the Ceilometer agents. Note that even if Kafka is
installed, OpenStack services send notifications into RabbiMQ, i.e. the plugin doesn't change anything in core
OpenStack services. To process this correctly, Ceilometer notification agent is configured to work with Kafka
and Rabbit simultaneously. Anyway, the Telemetry plugin will work without Kafka too, but there are some scalability
limitations, please see <limitation section>

Depending on message broker installed, Hindsight or Heka are used as collectors. Hindsight is used
to fetch Ceilometer Samples from Kafka and will be installed next on the same nodes as Kafka, whereas Heka
works with RabbitMQ and will be installed on controllers under Pacemaker.

The Telemetry plugin is better to be installed along with the StackLight plugins. In this case, the Telemetry plugin
will use the same databases as StackLight, i.e. InfluxDB and Elasticsearch. Otherwise, it is possible to configure
external storages.

By default, the OpenStack Telemetry plugin supports Ceilometer API partially: sample and statistics API are
supported by default. Anyway, it is possible to enable the full Ceilometer API support.

For more information about the plugin architecture, please see <architecture.rst>
