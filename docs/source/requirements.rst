.. _requirements:

Requirements
------------

The OpenStack Telemetry plugin has the following requirements:

======================= =================================
Requirement             Version/Comment
======================= =================================
Fuel                    9.0 on Mitaka
======================= =================================

If the external storages are used, the following requirements should be
satisfied:

+------------------------------------------------------------------+-----------------------------------------------------------------+
| Requirement                                                      | Version/Comment                                                 |
+==================================================================+=================================================================+
| An Elasticsearch server (for Ceilometer Resources and Events)    | 2.0.0 or higher, the RESTful API must be enabled over port 9200 |
+------------------------------------------------------------------+-----------------------------------------------------------------+
| A running InfluxDB server (for Ceilometer Samples)               | 0.10.0 or higher, the RESTful API must be enabled over port 8086|
+------------------------------------------------------------------+-----------------------------------------------------------------+


Compatibilities
---------------

If you don't want to install the backends on your own, you may use the
following StackLight plugins:

============================ ======================================
Plugin                       Version/Comment
============================ ======================================
StackLight InfluxDB-Grafana  0.10.0 or newer
StackLight ES-Kibana         0.10.2 or newer. If Resource API
                             is disabled, the version may be 0.10.0
============================ ======================================

To use Kafka as a MQ, the following should be installed:

========== ==================
Plugin       Version/Comment
========== ==================
Kafka            1.0.0
========== ==================
