.. _configure:

Configure the plugin
--------------------

To configure the OpenStack Telemetry plugin, please follow the seps below.

**To configure the OpenStack Telemetry plugin:**

1. Create an OpenStack environment as described in the `Fuel User Guide <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/create-environment.html>`_:


2. Make sure that the plugin is properly installed on the Fuel Master node.

   Go to the *Plugins* tab. You should see the following:

   .. image:: images/installed_telemetry_plugin.png
    :width: 100%

3. Enable the plugin.

   Go to the *Environments* tab and select *The OpenStack Telemetry Plugin* checkbox:

   .. image:: images/settings.png
    :width: 100%

4. The Telemetry plugin has Advanced Settings checkbox. Once it is chosen, you can enable Event API and
   Resource API:

   .. image:: images/advanced_settings.png
    :width: 100%

   If Advanced settings are chosen, you will be asked to configure Elasticsearch, because Ceilometer events
   and resources are stored there. You can use `local` database if you use Elasticsearch deployed by
   the Elasticsearch-Kibana plugin locally. Otherwise, please define IP and port for Elasticsearh you want to use.

5. Make sure that InfluxDB is configured properly:

   .. image:: images/influx.png
    :width: 100%

   You can use `local` database if you use InfluxDB deployed by the InfluxDB-Grafana plugin locally.
   Otherwise, please define IP/DNS name, port, database name, user and password (where Ceilometer-related data will be
   kept) for Elasticsearh you want to use.

6. Configure additional metadata to be kept along with Ceilometer samples in InfluxDB
   <TODO: the picture will be changed>

    .. image:: images/metadata.png
    :width: 100%

    By default, the Telemetry plugin will keep a list of metadata fields described here <TODO: add a link to list of
    metadata, it should be somewhere in this doc>. If this list is not sufficient, please add the names of metadata
    fields.