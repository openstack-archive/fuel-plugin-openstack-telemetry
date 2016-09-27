.. _install:

Introduction
------------

Before you install the OpenStack Telemetry plugin, verify that your
environment meets the requirements described in :ref:`requirements`.
You must have the Fuel Master node installed and configured before you can
install the plugin.

You can install the OpenStack Telemetry plugin using one of the following
options:

* Install using the RPM file
* Install from source

Install using the RPM file
--------------------------

**To install the OpenStack Telemetry plugin using the RPM file of the Fuel
plugins catalog:**

#. Download the OpenStack Telemetry plugin from the `Fuel plugins catalog <https://www.mirantis.com/validated-solution-integrations/fuel-plugins/>`_.

#. Copy the plugin ``.rpm`` file to the Fuel Master node:

   **Example:**

   .. code-block:: console

      # scp <TODO: plugin filename> root@fuel-master:/tmp

#. Log in to the Fuel Master node CLI as root.
#. Install the plugin using the
   `Fuel Plugins CLI <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/cli/cli_plugins.html>`_:

   .. code-block:: console
   
      # fuel plugins --install <TODO: plugin filename>

#. Verify that the plugin is installed correctly:

   .. code-block:: console
   
     # fuel plugins
     id | name          | version | package_version
     ---|---------------|---------|----------------
     1  | <TODO:name>   |<version>| <version>

#. Proceed to :ref:`configure`.

Install from source
-------------------

Alternatively, you may want to build the plugin RPM file from source if, for
example, you want to test the latest features of the master branch or
customize the plugin.

.. note:: Running a Fuel plugin that you built yourself is at your own risk
   and will not be supported.

To install the OpenStack Telemetry Plugin from source, first prepare an
environment to build the RPM file. The recommended approach is to build the
RPM file directly onto the Fuel Master node so that you will not have to copy
that file later on.

**To prepare an environment and build the plugin:**

#. Install the standard Linux development tools:

   .. code-block:: console

      [root@home ~] yum install createrepo rpm rpm-build dpkg-devel

#. Install the Fuel Plugin Builder. To do that, you should first get pip:

   .. code-block:: console

      [root@home ~] easy_install pip

#. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip`:

   .. code-block:: console

      [root@home ~] pip install fuel-plugin-builder

   .. note:: You may also need to build the Fuel Plugin Builder if the package
      version of the plugin is higher than the package version supported by the
      Fuel Plugin Builder you get from ``pypi``. For instructions on how to
      build the Fuel Plugin Builder, see the *Install Fuel Plugin Builder*
      section of the `Fuel Plugin SDK Guide <http://docs.openstack.org/developer/fuel-docs/plugindocs/fuel-plugin-sdk-guide/create-plugin/install-plugin-builder.html>`_.

#. Clone the plugin repository:

   .. code-block:: console

      [root@home ~] git clone https://github.com/openstack/fuel-plugin-openstack-telemetry

#. Verify that the plugin is valid:

   .. code-block:: console

      [root@home ~] fpb --check ./fuel-plugin-openstack-telemetry

#.  Build the plugin:

    .. code-block:: console

       [root@home ~] fpb --build ./fuel-plugin-openstack-telemetry

**To install the plugin:**

#. Once you create the RPM file, install the plugin:

   .. code-block:: console

      [root@fuel ~] fuel plugins --install ./fuel-plugin-openstack-telemetry/*.noarch.rpm

#. Verify that the plugin is installed correctly:

   .. code-block:: console

      # fuel plugins
      id | name          | version | package_version
      ---|---------------|---------|----------------
      1  | <TODO:name>   |<version>| <version>
