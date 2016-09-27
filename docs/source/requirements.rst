.. _requirements:

Requirements
------------

The OpenStack Telemetry plugin has the following requirements:

======================= =================================
Requirement             Version/Comment
======================= =================================
Fuel                    9.0 on Mitaka
======================= =================================

Compatibilities
---------------

To enable all Ceilometer API functionality and use the back ends installed by
StackLight, use the following StackLight plugins:

============================ =================================
Plugin                       Version/Comment
============================ =================================
StackLight InfluxDB-Grafana  0.10.0 or newer
StackLight ES-Kibana         0.10.2 or newer. If Resource API
                             is disabled, use 0.10.0.
============================ =================================

The OpenStack Telemetry plugin is also compatible with the Kafka plugin
version 1.0 or newer.