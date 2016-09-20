-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

require "kafka"
require "table"
local util = require "lma_utils"

local brokerlist     = read_config("brokerlist") or error("brokerlist must be set")
local topics         = read_config("topics") or error("topics must be set")
local consumer_conf  = read_config("consumer_conf")
local topic_conf     = read_config("topic_conf")
local decoder_module = read_config("decoder_module")
local send_error_messages = read_config("send_error_messages") or false
local inject         = inject_message

if decoder_module then
    inject = require(decoder_module).decode
    if not inject then
        error(decoder_module .. " does not provide a decode function")
    end
end

if type(brokerlist) == "table" then
    -- TODO(ityaptin) Research issue with several brokers
    -- brokerlist = table.concat(brokerlist, ",")
    brokerlist = table.remove(brokerlist, 1)
end

local consumer = kafka.consumer(brokerlist, topics, consumer_conf, topic_conf)

local err_msg = {
    Logger  = read_config("Logger"),
    Type    = "error",
    Payload = nil,
}

function process_message()
    while true do
        local msg, topic, partition, key = consumer:receive()
        if msg then
            local status, err = pcall(inject, msg)
            if status ~= 0 and send_error_messages then
                err_msg.Payload = err
                utils.safe_inject_message(err_msg)
            end
        end
    end
    return 0
end
