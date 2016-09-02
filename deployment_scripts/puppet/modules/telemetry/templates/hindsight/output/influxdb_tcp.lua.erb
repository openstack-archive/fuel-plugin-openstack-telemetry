--
-- Inspired from the lua_sandbox Postgres Output Example
-- https://github.com/mozilla-services/lua_sandbox/blob/f1ee9eb/docs/heka/output.md#example-postgres-output
--

local os = require 'os'
local http = require 'socket.http'

local write  = require 'io'.write
local flush  = require 'io'.flush

local influxdb_host = read_config('host') or error('influxdb host is required')
local influxdb_port = read_config('port') or error('influxdb port is required')
local username = read_config('username') or error('influxdb username is required')
local password = read_config('password') or error('influxdb password is required')

local batch_max_lines = read_config('batch_max_lines') or 1000
assert(batch_max_lines > 0, 'batch_max_lines must be greater than zero')

local db = read_config("database") or error("database config is required")

local write_url = string.format('http://%s:%d/write?db=%s&u=%s&p=%s', influxdb_host, influxdb_port, db, username, password)
local query_url = string.format('http://%s:%s/query', influxdb_host, influxdb_port)

local database_created = false


local data = {}
local lines_count = 0


local function write_batch()
    local body = table.concat(data) .. "\n"
    local resp_body, resp_status = http.request(write_url, body)
    write(resp_body, " : ", resp_status, "\n")
    flush()
    if resp_body and resp_status == 204 then
        -- success
        data = {}
        lines_count = 0
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
    local body = string.format('&u=%s&p=%s&q=CREATE DATABASE %s', username, password, db)
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


function process_message()
    if not database_created then
        create_database()
        database_created = true
    end

    local datalines = read_message("Payload")
    local _, count = string.gsub(datalines, "\n", "\n")
    table.insert(data, string.sub(datalines, 0, -1))
    lines_count = lines_count + count
    if lines_count >= batch_max_lines then
        write_batch()
    end

    return -4 -- batching
end


function timer_event(ns)
    if lines_count > 0 then
        local ok, err = write_batch()
        if ok then
            update_checkpoint()
        end
    end
end

