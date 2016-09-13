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
require "string"
require "cjson"
local utils = require "lma_utils"
local elasticsearch = require "elasticsearch"
local encoder_module = read_config("encoder") or error("Encoder should be defined")
local encoder = require(encoder_module)

local index = read_config("index") or "index"
local type_name = read_config("type_name") or "source"

function process_message()
    local code, payload = encoder.encode()
    if code == 0 then
        add_to_payload(payload)
        return utils.safe_inject_payload()
    else
        return code, payload
    end
end