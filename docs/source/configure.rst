.. _configure:

Configure the plugin
--------------------

Once installed, configure the OpenStack Telemetry plugin.

**To configure the OpenStack Telemetry plugin:**

#. Log in to the Fuel web UI.
#. Verify that the Telemetry Plugin is listed in the :guilabel:`Plugins` tab:

   .. image:: images/Installed_telemetry_plugin.png
      :width: 450pt

#. Create an OpenStack environment as described in the
   `Fuel User Guide <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/create-environment.html>`_
   or use an existing one.

#. To enable the plugin navigate to the :guilabel:`Environments` tab and
   select :guilabel:`The OpenStack Telemetry Plugin`:

   .. image:: images/settings.png
      :width: 450pt

#. Optional. To enable Event API and Resource API, select
   :guilabel:`Advanced Settings`:

   .. image:: images/advanced_settings.png
      :width: 450pt

   If selected, configure Elasticsearch. Ceilometer events and resources are
   stored there. Use the ``local`` database if you use Elasticsearch deployed
   by the Elasticsearch-Kibana plugin locally. Otherwise, define the IP and
   port for the Elasticsearch you want to use.

#. Configure InfluxDB:

   .. image:: images/Influx.png
      :width: 450pt

   Use the ``local`` database if you use InfluxDB deployed by the
   InfluxDB-Grafana plugin locally. Otherwise, define the IP or DNS name,
   port, database name, user, and password (where Ceilometer-related data will
   be kept) for the Elasticsearch you want to use.

#. Configure additional metadata to be kept along with Ceilometer samples in
   InfluxDB <TODO: the picture will be changed>.

   .. image:: images/metadata.png
      :width: 450pt

   By default, the Telemetry plugin keeps the list of metadata fields
   described here <TODO: add a link to list of metadata, it should be
   somewhere in this doc>. If this list is not sufficient, add the names of
   metadata fields.