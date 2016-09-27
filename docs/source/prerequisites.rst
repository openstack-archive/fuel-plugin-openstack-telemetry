.. _prerequisites:

Prerequisites
-------------

Prior to installing the OpenStack Telemetry plugin, you may want to install
the back-end services the plugin uses to store the data. These back-end
services include the following:

* Elasticsearch
* InfluxDB

To install the back-end services, use one of the options:

* Automatic installation within a Fuel environment using the following Fuel
  plugins:

  * `StackLight Elasticsearch-Kibana plugin
    <http://fuel-plugin-elasticsearch-kibana.readthedocs.io/en/latest>`__
  * `StackLight InfluxDB-Grafana plugin
    <http://fuel-plugin-influxdb-grafana.readthedocs.io/en/latest>`__

* Manual installation outside of a Fuel environment. The installation must
  comply with the :ref:`requirements` of the OpenStack Telemetry plugin.