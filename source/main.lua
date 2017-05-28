
local socket = require("socket")
local lunajson = require("lunajson")
local udp = socket.udp()
local uuid = require 'uuid.uuid'


udp:settimeout(0)
udp:setsockname('*', 12345)

local running = true
local clients = {}
local games = {}


uuid.seed()

local function processLogin(data)
    local cmd = data.input
    --print(cmd.user, cmd.password, "Validated")
    local session = uuid()

    local resp = {
		type='login',
		success = true,
		session = session
	}

    clients[session] = {id=cmd.user, session=session, address=data.address, port=data.port}
	udp:sendto(lunajson.encode(resp), data.address, data.port)
end

local function processJoinQueue(data) 
    local cmd = data.input

    table.insert(queue, {data.address, data.port})

    findGame()
end

local function findGame()
    if #queue == 2 then
        local blackPayer = queue[1]
        local whitePlayer = queue[2]

        table.remove(queue, 1)
        table.remove(queue, 1)
    end
end

local process = {
	login = processLogin,
	joinQueue = processJoinQueue,
}

while running do
	data, msg_or_ip, port_or_nil = udp:receivefrom()
    if data then
        --print(data, msg_or_ip, port_or_nil)
        local input = lunajson.decode(data)
        local cmd = input.cmd
        local data = {address = msg_or_ip, port = port_or_nil, input=input}
        print(string.format("FROM: %s:%d", msg_or_ip, port_or_nil))
        print("{")
        for i, v in pairs(input) do
            print("", i, v)
        end
        print("}")
        process[cmd](data)
    end
end