MockAccess = {}
MockAccess.__index = MockAccess

function MockAccess.__call(t, ...)
	t.mock.__calls[t.name] = t.mock.__calls[t.name] or {}
	local call_list = t.mock.__calls[t.name]
	call_list[#call_list+1] = {...}
end

function MockAccess:new(name, mock)
	local o = { name = name, mock = mock }
	setmetatable(o, self)
	return o
end

Mock = {}

function Mock.__index(t,k)
	return MockAccess:new(k, t)
end

function Mock:new()
	local o = { __calls = {} }
	setmetatable(o, self)
	return o
end

