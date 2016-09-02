-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

require "heka_kafka_consumer"
--[[
# Heka Kafka Consumer Input

## Sample Configuration
```lua
filename                = "heka_kafka.lua"
output_limit            = 8 * 1024 * 1024
brokerlist              = "localhost:9092" -- see https://github.com/edenhill/librdkafka/blob/master/src/rdkafka.h#L2205

-- in balanced consumer group mode a consumer can only subscribe on topics, not topics:partitions.
-- The partition syntax is only used for manual assignments (without balanced consumer groups).
topics                  = {"test"}
ticker_interval         = 60

-- https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md#global-configuration-properties
consumer_conf = {
    ["group.id"] = "test_group", -- must always be provided (a single consumer is considered a group of one
    -- in that case make this a unique identifier)
    ["message.max.bytes"] = output_limit,
}

-- https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md#topic-configuration-properties
topic_conf = {
    -- ["auto.commit.enable"] = true, -- cannot be overridden
    -- ["offset.store.method"] = "broker, -- cannot be overridden
}
```
--]]
require "string"
require "cjson"
require 'table'
require 'math'
require 'os'

local patt = require 'patterns'
local utils = require 'lma_utils'
local l = require 'lpeg'
l.locale(l)


local brokerlist    = read_config("brokerlist") or error("brokerlist must be set")
local topics        = read_config("topics") or error("topics must be set")
local consumer_conf = read_config("consumer_conf") or {}
local topic_conf    = read_config("topic_conf")

local write  = require "io".write
local flush  = require "io".flush

consumer_conf = {
    ["group.id"] = "test_group", -- must always be provided (a single consumer is considered a group of one
    -- in that case make this a unique identifier)
}

local consumer = heka_kafka_consumer.new(brokerlist, topics, consumer_conf, topic_conf)

local err_msg = {
    Logger  = read_config("Logger"),
    Type    = "error",
    Payload = nil,
}

local msg = {
    Logger  = read_config("Logger"),
    Type    = "kafka_message",
    Payload = nil,
    Fields = {}
}


function normalize_uuid(uuid)
   return patt.Uuid:match(uuid)
end

-- the metadata_fields parameter is a list of words separated by space
local fields_grammar = l.Ct((l.C((l.P(1) - l.P" ")^1) * l.P" "^0)^0)
local metadata_fields = fields_grammar:match(
   read_config("metadata_fields") or ""
)

local decode_resources = read_config('decode_resources') or false

local sample_msg = {
   Timestamp = nil,
   -- This message type has the same structure than 'bulk_metric'.
   Type = "ceilometer_samples",
   Payload = nil
}

local resource_msg = {
   Timestamp = nil,
   Type = "ceilometer_resource",
   Fields = nil,
}

function get_field(field, metadata)
   if type(metadata) ~= 'table' then
       return nil
   else
       local dot_ind = string.find(field,"%.")
       if dot_ind ~= nil then
           local length = string.len(field)
           local new_key = string.sub(field, 1, dot_ind - 1)
           local new_field = string.sub(field, dot_ind + 1, length)
           local value = get_field(new_field, metadata[new_key])
           return value
       else
           return metadata[field]
       end
   end
end

function inject_metadata(metadata, tags)
   local value
   for _, field in ipairs(metadata_fields) do
       value = get_field(field, metadata)
       if value ~= nil and type(value) ~= 'table' then
           if type(value) == 'string' then
               value = string.gsub(value, '.domain.tld', '')
           end
           tags["metadata." .. field] = value
       end
   end
end

function add_resource_to_payload(sample, payload)

   local resource_data = {
       timestamp = sample.timestamp,
       resource_id = sample.resource_id,
       source = sample.source or "",
       metadata = sample.resource_metadata,
       user_id = sample.user_id,
       project_id = sample.project_id,
       meter = {
           [sample.counter_name] = {
               type = sample.counter_type,
               unit = sample.counter_unit
           }
       }
   }
   payload[sample.resource_id] = resource_data
end


function add_sample_to_payload(sample, payload)
   local ts = patt.Timestamp:match(sample.timestamp)
   local curr_ts = os.time() * 1000000000
   local sample_data = {
       name='sample',
       timestamp = patt.Timestamp:match(sample.timestamp),
       values = {
           value = sample.counter_volume,
           message_id = sample.message_id,
           recorded_at = sample.recorded_at,
           timestamp = sample.timestamp,
           message_signature = sample.signature,
           type = sample.counter_type,
           unit = sample.counter_unit,
           delta = curr_ts - ts
       }
   }
   local tags = {
       meter = sample.counter_name,
       resource_id = sample.resource_id,
       project_id = sample.project_id ,
       user_id = sample.user_id,
       source = sample.source
   }
   inject_metadata(sample.resource_metadata or {}, tags)
   sample_data["tags"] = tags
   table.insert(payload, sample_data)
end

local err_msg = {
    Logger  = read_config("Logger"),
    Type    = "error",
    Payload = nil,
}

function safe_inject_message(message)
    local ok, err = pcall(inject_message, message)
    if not ok then
        err_msg.Payload = err
        pcall(inject_message, err_msg)
    end
end

function samples_to_heka_messages(payload, timestamp)
    local sample_payload = {}
    local resource_payload = {}
    for _, sample in ipairs(payload) do
        add_sample_to_payload(sample, sample_payload)
        if decode_resources then
            add_resource_to_payload(sample, resource_payload)
        end
    end
    sample_msg.Payload = cjson.encode(sample_payload)
    sample_msg.Timestamp = patt.Timestamp:match(timestamp)
    safe_inject_message(sample_msg)

    if decode_resources then
        resource_msg.Payload = cjson.encode(resource_payload)
        resource_msg.Timestamp = patt.Timestamp:match(timestamp)
        safe_inject_message(resource_msg)
    end
    return 0
end

function safe_logged_call(func, arg)
    local ok, result = pcall(func, arg)
    if not ok then
        err_msg.Payload = result
        pcall(inject_message, err_msg)
        return ok, nil
    end
    return ok, result
end

function process_message()
    local ok = 0
    local message_body = nil
    while true do
        local message, topic, partition, key = consumer:receive()
        if message then

            ok, message = safe_logged_call(cjson.decode, message)
            if ok then
              ok, message_body = safe_logged_call(cjson.decode, message['oslo.message'])
              if ok and message_body and message_body.payload then
                  samples_to_heka_messages(message_body.payload, message_body.timestamp)
              end
            end
        end
      err = 0
      message_body = nil
    end
    return 0 -- unreachable but here for consistency
end


