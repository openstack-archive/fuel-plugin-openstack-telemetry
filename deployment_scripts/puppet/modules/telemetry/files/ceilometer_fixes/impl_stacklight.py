#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
"""Backend implementation compatible with StackLight storages"""

import elasticsearch as es
import influxdb
import influxdb.exceptions
import influxdb.resultset
from oslo_config import cfg
from oslo_log import log
from oslo_utils import netutils

import ceilometer
from ceilometer.i18n import _LE
from ceilometer.storage import base
from ceilometer.storage.es import utils as es_utils
from ceilometer.storage.influx import utils as influx_utils
from ceilometer.storage.metrics import units
from ceilometer import utils

LOG = log.getLogger(__name__)

OPTS = [
    cfg.IntOpt('influxdb_replication',
               min=1,
               default=1,
               help="Replication factor for InfluxDB retention policy in "
                    "seconds."),
    cfg.StrOpt('resource_connection',
               secret=True,
               help='The connection string used to connect to the resource '
                    'database.'),
]

cfg.CONF.register_opts(OPTS, group='database')

AVAILABLE_CAPABILITIES = {
    'resources': {'query': {'simple': False,
                            'metadata': False}},
    'statistics': {'groupby': True,
                   'query': {'simple': True,
                             'metadata': True},
                   'aggregation': {'standard': True,
                                   'selectable': {'max': True,
                                                  'min': True,
                                                  'sum': True,
                                                  'avg': True,
                                                  'count': True,
                                                  'stddev': True,
                                                  'cardinality': False}}},
    'meters': {'query': {'simple': False,
                         'metadata': False}},
    'samples': {'query': {'simple': False,
                          'metadata': False,
                          'complex': False}},
}

AVAILABLE_STORAGE_CAPABILITIES = {
    'storage': {'production_ready': True},
}


class Connection(base.Connection):
    """Get Ceilometer data from InfluxDB and ElasticSearch databases.

    Samples are stored in the following format in InfluxDB:
    - measurement: sample
    - tags (indexed): user_id, resource_id, project_id, source and
    configured metadata fields
    - fields (not indexed): counter_type -> type, counter_unit -> unit,
    counter_volume -> value, counter_name -> meter, message_id,
    message_signature, timestamp and recorded_at.

    Resources and meters are stored in ElasticSearch.
    Resources:
     {
      "_index": "ceilometer_resource",
      "_type": "<source>",
      "_id": "<resource_id>",
      "_source":{
          "first_sample_timestamp": "<datetime in isoformat>",
          "last_sample_timestamp": "<datetime in isoformat>",
          "project_id": "<project_id>",
          "user_id": "<user_id>",
          "metadata": {
              "foo" : "bar",
              "foofoo" : {"barbar": {"foo": "bar"}}
          },
          "meters": {"<meter_name>": {"unit": "<meter_unit>",
                                      "type": "<meter_type>"}
       }
    }

    This class has 'record_metering_data' implementation, but it is used only
    for testing needs. In real life, data will be recorded by StackLight

    """

    CAPABILITIES = utils.update_nested(base.Connection.CAPABILITIES,
                                       AVAILABLE_CAPABILITIES)

    STORAGE_CAPABILITIES = utils.update_nested(
        base.Connection.STORAGE_CAPABILITIES,
        AVAILABLE_STORAGE_CAPABILITIES,
    )

    resource_index = "ceilometer_resource"

    _refresh_on_write = False

    def __init__(self, url):
        if cfg.CONF.database.resource_connection:
            url_split = netutils.urlsplit(
                cfg.CONF.database.resource_connection)
            self.resource_connection = es.Elasticsearch(url_split.netloc)
        else:
            self.resource_connection = None

        user, pwd, host, port, self.database = influx_utils.split_url(url)
        self.sample_connection = influxdb.InfluxDBClient(host, port, user, pwd,
                                                         self.database)

    def upgrade(self):
        self.upgrade_resource_database()
        self.upgrade_sample_database()

    def upgrade_resource_database(self):
        if not self.resource_connection:
            return

        iclient = es.client.IndicesClient(self.resource_connection)
        template = {
            'template': 'ceilometer_*',
            'mappings': {
                '_default_': {
                    'properties': {
                        'first_sample_timestamp': {'type': 'date'},
                        'last_sample_timestamp': {'type': 'date'},
                    },
                    "dynamic_templates": [
                        {
                            "string_fields": {
                                "match": "*",
                                "match_mapping_type": "string",
                                "mapping": {
                                    "type": "string",
                                    "index": "not_analyzed"
                                }
                            }
                        }
                    ]
                }
            }
        }
        iclient.put_template(name='ceilometer_resource_template',
                             body=template)
        iclient.create(self.resource_index)

    def upgrade_sample_database(self):
        try:
            self.sample_connection.create_database(self.database)
        except influxdb.exceptions.InfluxDBClientError as e:
            if "database already exists" not in e.content:
                raise
        self.sample_connection.create_retention_policy(
            name=influx_utils.RETENTION_POLICY_NAME,
            duration="INF",
            replication=cfg.CONF.database.influxdb_replication,
            database=self.database,
            default=True)
        if cfg.CONF.database.metering_time_to_live > 0:
            duration = "%ss" % cfg.CONF.database.metering_time_to_live
            self.sample_connection.alter_retention_policy(
                name=influx_utils.RETENTION_POLICY_NAME,
                database=self.database,
                duration=duration,
                replication=cfg.CONF.database.influxdb_replication,
                default=True
            )

    def get_meters(self, user=None, project=None, resource=None, source=None,
                   metaquery=None, limit=None, unique=None):
        if not self.resource_connection:
            raise base.NoResultFound(
                "Resource connection url is not defined and "
                "meter requests could not be processed")

        if limit == 0:
            return

        q_args = es_utils.make_query(self.resource_index, resource=resource,
                                     user=user, project=project, source=source,
                                     metaquery=metaquery, limit=limit)
        results = self.resource_connection.search(
            fields=['_type', '_id', '_source'],
            **q_args)
        return es_utils.search_results_to_meters(results, limit, unique)

    def get_resources(self, user=None, project=None, source=None,
                      start_timestamp=None, start_timestamp_op=None,
                      end_timestamp=None, end_timestamp_op=None,
                      metaquery=None, resource=None, limit=None):
        if not self.resource_connection:
            raise base.NoResultFound(
                "Resource connection url is not defined and "
                "resource requests could not be processed")

        if limit == 0:
            return

        q_args = es_utils.make_query(self.resource_index, user, project,
                                     source, start_timestamp,
                                     start_timestamp_op, end_timestamp,
                                     end_timestamp_op, metaquery, resource,
                                     limit)
        results = self.resource_connection.search(
            fields=['_type', '_id', '_source'],
            **q_args)
        return es_utils.search_results_to_resources(results)

    def get_meter_statistics(self, sample_filter, period=None, groupby=None,
                             aggregate=None):

        # Note InfluxDB should have a lower time bound in query,
        # otherwise it will be defined as 1970-01-01T00:00:00.
        if (groupby and set(groupby) -
            set(['user_id', 'project_id', 'resource_id', 'source',
                 'resource_metadata.instance_type'])):
            raise ceilometer.NotImplementedError(
                "Unable to group by these fields")
        if any([aggr.func == 'cardinality' for aggr in (aggregate or [])]):
            raise ceilometer.NotImplementedError(
                "Cardinality aggregation is not supported "
                "by StackLight backends"
            )
        try:
            if (not sample_filter.start_timestamp or
                    not sample_filter.end_timestamp):
                first, last = self.get_time_boundary(sample_filter)
                sample_filter.start_timestamp = \
                    sample_filter.start_timestamp or first
            unit = self.get_unit(sample_filter)
        except base.NoResultFound:
            return []

        query = influx_utils.make_aggregate_query(sample_filter, period,
                                                  groupby, aggregate)
        response = self._query(query)
        stats = []
        for serie, points in response.items():
            measurement, tags = serie
            for point in points or []:
                stats.append(
                    influx_utils.point_to_stat(point, tags, period, aggregate,
                                               unit))
        return [stat for stat in stats if stat]

    def get_samples(self, sample_filter, limit=None):
        if limit is 0:
            return
        response = self._query(
            influx_utils.make_list_query(sample_filter, limit))
        for point in response.get_points(influx_utils.MEASUREMENT):
            yield influx_utils.point_to_sample(point)

    def query_samples(self, filter_expr=None, orderby=None, limit=None):
        q = influx_utils.make_complex_query(filter_expr, limit)
        response = self._query(q)
        samples = []
        for point in response.get_points(influx_utils.MEASUREMENT):
            samples.append(influx_utils.point_to_sample(point))
        return influx_utils.sort_samples(samples, orderby)

    def get_unit(self, sample_filter):
        meter = sample_filter.meter
        if meter in units.UNITS_BY_METRIC:
            return units.UNITS_BY_METRIC[meter]
        response = self._query(
            influx_utils.make_unit_query(sample_filter))
        try:
            point = response.get_points(influx_utils.MEASUREMENT).next()
        except StopIteration:
            raise base.NoResultFound()

        units.UNITS_BY_METRIC[meter] = point['unit']
        return point['unit']

    def get_time_boundary(self, sample_filter):
        """Find timestamp of the first matching sample in the database."""

        response = self._query(
            influx_utils.make_time_bounds_query(sample_filter))
        try:
            first_point = response.get_points(influx_utils.MEASUREMENT).next()
        except StopIteration:
            raise base.NoResultFound()

        start_timestamp = utils.sanitize_timestamp(first_point['first'])
        end_timestamp = utils.sanitize_timestamp(first_point['last'])
        return start_timestamp, end_timestamp

    def _query(self, q):
        """Make a query to InfluxDB database.

          :param q: Query string in InfluxDB query format.
          :returns a response ResultSet
        """
        LOG.debug("InfluxDB query requested: %s" % q)
        try:
            return self.sample_connection.query(q)
        except influxdb.exceptions.InfluxDBClientError as e:
            LOG.exception(_LE("Client error during the InfluxDB query: %s"), e)
            return influxdb.resultset.ResultSet({})

    def record_metering_data(self, data):
        """Records data into databases

        Method is needed for testing needs only. In real life, data will be
        written to the databases by StackLight.
        """
        data['counter_name'] = utils.decode_unicode(data['counter_name'])
        self.resource_connection.update(
            index=self.resource_index, doc_type='source',
            id=data['resource_id'], body=es_utils.sample_to_resource(data)
        )
        self.sample_connection.write_points(
            [influx_utils.sample_to_point(data)], "n", self.database,
            influx_utils.RETENTION_POLICY_NAME)
        if self._refresh_on_write:
            self.resource_connection.indices.refresh(self.resource_index)
            while self.resource_connection.cluster.pending_tasks(
                    local=True)['tasks']:
                pass

    def clear(self):
        self.resource_connection.indices.delete(index=self.resource_index,
                                                ignore=[400, 404])
        self.sample_connection.drop_database(self.database)
