.. _requirements:

Requirements
------------

The OpenStack Telemetry plugin has the following requirements:

======================= =================================
Requirement             Version/Comment
======================= =================================
Fuel                    >= 9.0
======================= =================================

Compatibilities
---------------

If you want to enable all Ceilometer API functionality and use the backends installed by StackLight,
the following StackLight plugins should be used:

============================ =================================
Requirement                           Version/Comment
============================ =================================
StackLight InfluxDB-Grafana            >= 0.10.0
StackLight ES-Kibana                   >= 0.10.2 / If Resource API is disabled, you can use >= 0.10.0
============================ =================================

The OpenStack Telemetry plugin is compatible with the Kafka plugin:

======================= =================================
Requirement             Version/Comment
======================= =================================
Kafka plugin                    >= 1.0
======================= =================================