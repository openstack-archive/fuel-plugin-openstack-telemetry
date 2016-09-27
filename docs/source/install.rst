.. _install:

Install the plugin
------------------

Before you install the OpenStack Telemetry plugin, verify that your
environment meets the requirements described in :ref:`requirements`.
You must have the Fuel Master node installed and configured before you can
install the plugin. Typically, you install a Fuel plugin before you deploy an
OpenStack environment. However, the Telemetry plugin is hot-pluggable, so you
can install it later.

**To install the OpenStack Telemetry plugin:**

#. Download the OpenStack Telemetry plugin from the `Fuel Plugins Catalog`_.

#. Copy the plugin ``.rpm`` package to the Fuel Master node:

   **Example:**

   .. code-block:: console

      # scp <plugin filename> root@fuel-master:/tmp

#. Log in to the Fuel Master node CLI as root.
#. Install the plugin by typing:

   .. code-block:: console
   
      # fuel plugins --install <plugin filename>

#. Verify that the plugin is installed correctly:

   .. code-block:: console
   
     # fuel plugins
     id | name          | version | package_version
     ---|---------------|---------|----------------
     1  | <name>        |<version>| <version>

#. Proceed to :ref:`configure`.

.. _Fuel Plugins Catalog: https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/
