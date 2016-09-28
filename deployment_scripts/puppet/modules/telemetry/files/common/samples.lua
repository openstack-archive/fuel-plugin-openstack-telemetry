-- Copyright 2016 Mirantis, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local cjson = cjson
local string = string
local table = table
local math = math
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local type = type

local patt = require 'patterns'
local utils = require 'lma_utils'
local l = require 'lpeg'
l.locale(l)

function normalize_uuid(uuid)
    return patt.Uuid:match(uuid)
end

local metadata_fields = {}

local SamplesDecoder = {}
SamplesDecoder.__index = SamplesDecoder

setfenv(1, SamplesDecoder) -- Remove external access to contain everything in the module

function normalize_uuid(uuid)
    return patt.Uuid:match(uuid)
end

-- Mapping table defining transformation functions to be applied, keys are the
-- attributes in the notification's payload and values are Lua functions
local transform_functions = {
    created_at = utils.format_datetime,
    launched_at = utils.format_datetime,
    deleted_at = utils.format_datetime,
    terminated_at = utils.format_datetime,
    user_id = normalize_uuid,
    project_id = normalize_uuid,
}

function map(func, tbl)
     local mapped_table = {}
     for i,v in pairs(tbl) do
         mapped_table[i] = func(v)
     end
     return mapped_table
end

local sample_msg = {
    Timestamp = nil,
    -- This message type has the same structure than 'bulk_metric'.
    Type = "ceilometer_samples",
    Payload = nil
}

function parse_metadata_field(field)
    local from = 1
    local to = string.find(field, "%.")
    if to ~= nil then
        local field_t = {}
        while to do
            table.insert(field_t, string.sub(field, from, to - 1))
            from = to + 1
            to = string.find(field, "%.", from)
        end
        table.insert(field_t, string.sub(field, from))
        return field_t
    else
        return field
    end

end

function parse_metadata_fields(fields)
    local parsed_fields = {}
    for _, field in ipairs(fields) do
        parsed_fields[field] = parse_metadata_field(field)
    end
    return parsed_fields
end

function get_field(field, metadata)
    local value = nil
    if type(metadata) == 'table' then
        if type(field) == 'table' then
            value = metadata
            for _, field_part in ipairs(field) do
                if not value then
                    break
                end
                value = value[field_part]
            end
        else
            value = metadata[field]
        end
    end
    return value
end


function SamplesDecoder:inject_metadata(metadata, tags)
    local value
    for field_name, field_tbl in pairs(self.metadata_fields) do
        value = get_field(field_tbl, metadata)
        if value ~= nil and type(value) ~= 'table' then
            local transform = transform_functions[field_name]
            if transform ~= nil then
                tags["metadata." .. field_name] = transform(value)
            else
                tags["metadata." .. field_name] = value
            end
        end
    end
end

function SamplesDecoder:add_sample_to_payload(sample, payload)
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
            unit = sample.counter_unit
        }
    }
    local tags = {
        meter = sample.counter_name,
        resource_id = sample.resource_id,
        project_id = sample.project_id ,
        user_id = sample.user_id,
        source = sample.source
    }
    self:inject_metadata(sample.resource_metadata or {}, tags)
    sample_data["tags"] = tags
    table.insert(payload, sample_data)
end

-- Create a new Sample decoder
--
-- metadata fields: line with metadata fields to store
-- from samples separated by space
function SamplesDecoder.new(metadata_fields)
    local e = {}
    setmetatable(e, SamplesDecoder)
    e.metadata_fields = parse_metadata_fields(metadata_fields)
    return e
end


-- Decode Ceilometer samples

-- data: oslo.messaging message with Ceilometer samples
-- returns ok and sample or error message
function SamplesDecoder:decode (data)
    local ok, message = pcall(cjson.decode, data)
    if not ok then
        return -2, "Cannot decode Payload"
    end
    local ok, message_body = pcall(cjson.decode, message["oslo.message"])
    if not ok then
        return -2, "Cannot decode Payload[oslo.message]"
    end
    local sample_payload = {}
    if message_body['payload'] then
        for _, sample in ipairs(message_body["payload"]) do
            self:add_sample_to_payload(sample, sample_payload)
        end
        sample_msg.Payload = cjson.encode(sample_payload)
        sample_msg.Timestamp = patt.Timestamp:match(message_body.timestamp)
        return 0, sample_msg
    end
    return -2, "Empty message"
end

return SamplesDecoder
