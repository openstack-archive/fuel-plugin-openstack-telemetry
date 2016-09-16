--
-- Inspired from the lua_sandbox Postgres Output Example
-- https://github.com/mozilla-services/lua_sandbox/blob/f1ee9eb/docs/heka/output.md#example-postgres-output
--

local os = require 'os'
local http = require 'socket.http'

local influxdb = require 'influxdb'

local influxdb_host = read_config('host') or error('influxdb host is required')
local influxdb_port = read_config('port') or error('influxdb port is required')
local influxdb_user = read_config('username')
local influxdb_password = read_config('password')
local batch_max_lines = read_config('batch_max_lines') or 3000
assert(batch_max_lines > 0, 'batch_max_lines must be greater than zero')

local db = read_config("database") or error("database config is required")
local database_created = false

local debug_output = read_config("debug") or false
local write
local flush

if debug_output then
    write = require("io").write
    flush = require("io").flush
end

local buffer = {}
local buffer_len = 0

local encoder = influxdb.new(time_precision)

local function make_write_url()
    local url = string.format('http://%s:%d/write?db=%s', influxdb_host,
                              influxdb_port, db)
    if influxdb_user and influxdb_password then
        url = string.format("%s&u=%s&p=%s", url, influxdb_user, influxdb_password)
    end
    return url
end

local function make_get_url()
    local url = string.format('http://%s:%s/query', influxdb_host, influxdb_port)
    if influxdb_user and influxdb_password then
        url = string.format("%s?u=%s&p=%s", url, influxdb_user, influxdb_password)
    end
    return url
end

local write_url = make_write_url()
local query_url = make_get_url()


local function write_batch()
    assert(buffer_len > 0)
    local body = table.concat(buffer, '\n')
    local resp_body, resp_status = http.request(write_url, body)
    if write then
        write("Write request status: ", resp_status,
              ". Write response: ", resp_body, "\n")
        flush()
    end
    if resp_body and resp_status == 204 then
        -- success
        buffer = {}
        buffer_len = 0
        return resp_body, ''
    else
        -- error
        local err_msg = resp_status
        if resp_body then
            err_msg = string.format('influxdb write error: [%s] %s',
                resp_status, resp_body)
        end
        return nil, err_msg
    end
end


local function create_database()
    -- query won't fail if database already exists
    local body = string.format('q=CREATE DATABASE %s', db)
    local resp_body, resp_status = http.request(query_url, body)
    if resp_body and resp_status == 200 then
        -- success
        return resp_body, ''
    else
        -- error
        local err_msg = resp_status
        if resp_body then
            err_msg = string.format('influxdb create database error [%s] %s',
                resp_status, resp_body)
        end
        return nil, err_msg
    end
end


function process_bulk_metric()
    -- The payload of the message contains a list of datapoints.
    --
    -- Each point is formatted either like this:
    --
    --  {name='foo',
    --   value=1,
    --   tags={k1=v1,...}}
    --
    -- or like this for multi-value points:
    --
    --  {name='bar',
    --   values={k1=v1, ..},
    --   tags={k1=v1,...}
    --
    local ok, points = pcall(cjson.decode, read_message("Payload"))
    if not ok or not points then
        return nil, 'Invalid payload value for bulk metric'
    end

    local msg_timestamp = read_message('Timestamp')
    for _, point in ipairs(points) do
        point.tags = point.tags or {}
        line = encoder:encode_datapoint(
            point.timestamp or msg_timestamp,
            point.name,
            point.value or point.values,
            point.tags)
        buffer_len = buffer_len + 1
        buffer[buffer_len] = line
    end
    return true, nil
end

function process_message()

    if not database_created then
        local ok, err_msg = create_database()
        if not ok then
            return -3, err_msg  -- retry
        end
        database_created = true
    end

    local ok, err_msg = process_bulk_metric()
    if not ok then
        -- the message is not valid, skip it
        return -2, err_msg  -- skip
    end

    if buffer_len > batch_max_lines then
        local ok, err_msg = write_batch()
        if not ok then
            return -3, err_msg  -- retry
        end
        return 0
    end

    return -4 -- batching
end


function timer_event(ns)
    if buffer_len > 0 then
        local ok, _ = write_batch()
        if ok then
            update_checkpoint()
        end
    end
end
