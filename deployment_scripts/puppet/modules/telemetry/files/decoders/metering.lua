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
local utils = require 'lma_utils'
local l = require 'lpeg'
l.locale(l)

local decoder_module = read_config('decoder') or error("Decoder module should be defined") 

local inject = utils.safe_inject_message

if decoder_module then
    inject = require(decoder_module).decode
    if not inject then
        error(decoder_module .. " does not provide a decode function")
    end
end

function process_message ()
    local data = read_message("Payload")
    local code, msg = inject(data)
    return code, msg
end