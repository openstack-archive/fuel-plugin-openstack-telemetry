.. _requirements:

Requirements
------------

The OpenStack Telemetry plugin has the following requirements:

======================= =================================
Requirement             Version/Comment
======================= =================================
Fuel                    9.0 on Mitaka
======================= =================================

If you use external storages:

+----------------------------------+-----------------------------------------+
| Requirement                      | Version/Comment                         |
+==================================+=========================================+
| An Elasticsearch server (for     | 2.0.0 or higher, the RESTful API must be|
| Ceilometer Resources and Events) | enabled over port 9200                  |
+----------------------------------+-----------------------------------------+
| A running InfluxDB server (for   | 0.10.0 or higher, the RESTful API must  |
| Ceilometer Samples)              | be enabled over port 8086               |
+----------------------------------+-----------------------------------------+


Compatibilities
---------------

The OpenStack Telemetry plugin is compatible with the following plugins:

* To install the back-end services automatically, use the following StackLight
  plugins:

  ============================ ======================================
  Plugin                       Version/Comment
  ============================ ======================================
  StackLight InfluxDB-Grafana  0.10.0 or newer
  StackLight ES-Kibana         0.10.2 or newer. If Resource API
                               is disabled, the version may be 0.10.0
  ============================ ======================================

* To use Kafka as a message queue, install:

  ========== ==================
  Plugin       Version/Comment
  ========== ==================
  Kafka      1.0.0
  ========== ==================