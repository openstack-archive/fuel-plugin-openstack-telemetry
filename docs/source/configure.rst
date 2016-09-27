.. _configure:

Configure the plugin
--------------------

Once installed, configure the OpenStack Telemetry plugin.

**To configure the OpenStack Telemetry plugin:**

#. Log in to the Fuel web UI.
#. Verify that the Telemetry plugin is listed in the :guilabel:`Plugins` tab:

   .. image:: images/installed_telemetry_plugin.png
      :width: 450pt

#. Create an OpenStack environment as described in the
   `Fuel User Guide <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/create-environment.html>`_
   or use an existing one.

#. To enable the plugin, navigate to the :guilabel:`Environments` tab and
   select :guilabel:`The OpenStack Telemetry Plugin`:

   .. image:: images/settings.png
      :width: 450pt

#. Optional. To enable Event API and Resource API, select
   :guilabel:`Advanced Settings`:

   .. image:: images/advanced_settings.png
      :width: 450pt

   If selected, configure Elasticsearch that stores Ceilometer events and
   resources:

   * Select :guilabel:`Use local Elasticsearch` if you have deployed the
     Elasticsearch-Kibana plugin.
   * Otherwise, select :guilabel:`Use External Elasticsearch` and define the
     IP and port for the Elasticsearch you want to use.

#. Configure InfluxDB:

   .. image:: images/influx.png
      :width: 450pt

   * Select :guilabel:`Use local InfluxDB` if you have deployed the
     InfluxDB-Grafana plugin.
   * Otherwise, select :guilabel:`Use External InfluxDB` and define the IP or
     DNS name, port, database name, username, and password for the
     Elasticsearch you want to use to keep the Ceilometer-related data.

#. Configure additional metadata to be kept along with Ceilometer samples in
   InfluxDB:

   .. image:: images/metadata.png
      :width: 450pt

   By default, the Telemetry plugin keeps the list of metadata fields
   described in the :ref:`limitations` section. If this list is not
   sufficient, add the names of metadata fields.