MockAccessor = {}
MockAccessor.__index = MockAccessor

function MockAccessor.__call(t, ...)
	t.mock.__calls[t.name] = t.mock.__calls[t.name] or {}
	local call_list = t.mock.__calls[t.name]
	call_list[#call_list+1] = {...}
end

function MockAccessor:new(name, mock)
	local o = { name = name, mock = mock }
	setmetatable(o, self)
	return o
end

Mock = {}

function Mock.__index(t,k)
	return MockAccessor:new(k, t)
end

function Mock:new()
	local o = { __calls = {} }
	setmetatable(o, self)
	return o
end

matchers = matchers or {}

function matchers.was_called(target, value)
	if getmetatable(target) ~= MockAccessor then
		return false, "target must a MockAccessor"
	end
	
	local calls = target.mock.__calls[target.name]
	
	if not calls or #calls ~= value then
		return false, "expecting "..value.." calls"
	end
	return true
end