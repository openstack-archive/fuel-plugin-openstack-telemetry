.. _architecture:

Architecture overview
---------------------

   .. image:: images/arch-diagram.png
    :width: 100%

On the picture above you can see almost all pieces of the solution. Hindsight/Heka is drown
separately because it will live in different places depending what is actually chosen.
Ceilometer agents are deployed as usual:

1. Central agents lives on controllers. This service is needed to poll metrics about OpenStack services.
   Note: if Kafka is not deployed, only one central agent will be running on the env under pacemaker. If
   Kafka is deployed, the coordination mechanism with Zookeeper will be automatically enabled. For more information
   about coordination, please see <TODO: add a link to Ceilometer docs>. After a central agent gets the measurements,
   it sends it to the queue named notifications.sample.

2. Compute agents work on computes. The main difference from central agents is metadata cache usage. The Telemetry
   plugin enables this feature. Nova API will be asked for instance metadata every 10 minutes, but not every polling
   interval. Please see the official Telemetry docs for more information <TODO: add a link>. After a compute agent gets
   the measurements, it sends it to the queue named notifications.sample.

3. Notification agents live on controllers too. Each notification agent does the following: gets data from polling
   agents and OpenStack services (in other words, listen to notifications.sample and notifications.info queues),
   does some transformations and send data further. The telemetry plugin may be customized at this point. By default,
   Ceilometer notification agents will not convert OpenStack notifications to Ceilometer Events. If you enable this
   functionality <TODO add link to installation>, notification agents will write Events directly to ElasticSearch
   with direct:// publisher. In any case, notification agents send measurements to `metering.sample` queue. Note: in MOS
   Ceilometer, notification agents don't need coordination. Please see the following docs for details <TODO: add he link
   to transformers stuff for Ceilometer in MOS 9.0>

A Notification agent is the last Ceilometer-related processor. As a Ceilometer "output", we have all collected
data in `metering.sample` queue and Ceilometer Event already written into Elasticsearch (if Event API is enabled).
Note that Ceilometer agents don't depend on the MQ we use because they work with MQ through oslo.messaging.

To continue data processing, Hindsight or Heka are used. This solution is inspired by the StackLight plugins,
which use Heka as message processor. See the following docs to become familiar with Heka: <TODO: add links>.
Unfortunately, Heka cannot work properly with Kafka. To solve this problem, we've decided to use a "new generation"
of Heka called Hindsight <TODO: add a link here>. It supports all needed Kafka functionality, but on the other hand,
Hindsight cannot be used to work with RabbitMQ.
Thus, the both instruments should be used depending on the MQ:

1. If Kafka is deployed, Hindsight is deployed on the same nodes where Kafka is running. Hindsight is started with
   4 input plugins to make data consumption fast enough. Hindsight services are not running under pacemaker, but the
   service will be restarted automatically in case of any failures. Heka will not be started.

2. If Kafka is not installed, RabbitMQ will be used as a transport system. To deal with this case, Heka will be
   running on each controller under pacemaker. Hindsight will not be running.

Once Heka/Hindsight receives a data sample, it will be processed through a chain of plugins and finally will be
send to InfluxDB/Elasticsearch.

