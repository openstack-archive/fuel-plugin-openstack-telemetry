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

local table = require 'table'

local samples = require 'samples'
local resources = require 'resources'
local patt = require 'patterns'
local utils = require 'lma_utils'

local l = require 'lpeg'
l.locale(l)

local fields_grammar = l.Ct((l.C((l.P(1) - l.P" ")^1) * l.P" "^0)^0)
local metadata_fields = fields_grammar:match(
    read_config("metadata_fields") or ""
)
local decode_resources = read_config('decode_resources') or false


local samples_decoder = samples.new(metadata_fields)
local resource_decoder = nil

if decode_resources then
    resource_decoder = resources.new()
end

local CeilometerDecoder = {}
CeilometerDecoder.__index = CeilometerDecoder

setfenv(1, CeilometerDecoder) -- Remove external access to contain everything in the module

function inject(code, msg)
    if code == 0 and msg then
        return utils.safe_inject_message(msg)
    else
        return code, msg
    end
end

function decode(data)
    local code, msg = inject(samples_decoder:decode(data))
    if code == 0 and resource_decoder then
        code, msg = inject(resource_decoder:decode(data))
    end
    return code, msg
end

return CeilometerDecoder
