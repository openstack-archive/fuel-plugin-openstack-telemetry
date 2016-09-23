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

local ResourcesDecoder = {}
ResourcesDecoder.__index = ResourcesDecoder

setfenv(1, ResourcesDecoder) -- Remove external access to contain everything in the module

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

local resource_msg = {
    Timestamp = nil,
    Type = "ceilometer_resources",
    Payload = nil
}

function add_resource_to_payload(sample, payload)
    local counter_name, _ = string.gsub(sample.counter_name, "%.", "\\")

    local resource_data = {
        timestamp = sample.timestamp,
        resource_id = sample.resource_id,
        source = sample.source or "",
        metadata = sample.resource_metadata,
        user_id = sample.user_id,
        project_id = sample.project_id,
        meter = {
            [counter_name] = {
                type = sample.counter_type,
                unit = sample.counter_unit
            }
        }
    }
    payload[sample.resource_id] = resource_data
end

function ResourcesDecoder.new()
    local e = {}
    setmetatable(e, ResourcesDecoder)
    return e
end

-- Decode Ceilometer samples to resource messages

-- data: oslo.messaging message with Ceilometer samples
-- returns ok and resource or error message
function ResourcesDecoder:decode (data)
    local ok, message = pcall(cjson.decode, data)
    if not ok then
        return -2, "Cannot decode Payload"
    end
    local ok, message_body = pcall(cjson.decode, message["oslo.message"])
    if not ok then
        return -2, "Cannot decode Payload[oslo.message]"
    end
    local resource_payload = {}
    if message_body['payload'] then
        for _, sample in ipairs(message_body["payload"]) do
            add_resource_to_payload(sample, resource_payload)
        end
        resource_msg.Payload = cjson.encode(resource_payload)
        resource_msg.Timestamp = patt.Timestamp:match(message_body.timestamp)
        return 0, resource_msg
    end
    return -2, "Empty message"
end

return ResourcesDecoder
