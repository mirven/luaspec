Mock = { calls = {}, return_values = {} }

-- we store all calls and requested return values indexed
-- by the mock object, we don't want to hold onto references
-- when they should be garbage collected to make the tables
-- be weak
setmetatable(Mock.calls, { __mode="k" })
setmetatable(Mock.return_values, { __mode="k" })

function Mock.__call(mock, ...)
	Mock.calls[mock] = Mock.calls[mock] or {}
	local calls = Mock.calls[mock]
	calls[#calls+1] = {...}
	
	local return_values = Mock.return_values[mock]
	
	if return_values then
		return unpack(return_values)
	end
end

function Mock.__index(mock, k)
	local new_mock = Mock:new()
	rawset(mock, k, new_mock)
	return new_mock
end

function Mock:new()
	local mock = { should_return = self.should_return }
	setmetatable(mock, self)
	return mock
end

function Mock:should_return(...)
	if getmetatable(self) ~= Mock then
		error("should_return must be called with : operator", 2)
	end
	Mock.return_values[self] = {...}
end

-- define matchers used with mocks

matchers = matchers or {}

function matchers.was_called(target, value)
	if getmetatable(target) ~= Mock then
		return false, "target must be a Mock"
	end
	
	local calls = Mock.calls[target] or {}
	
	if #calls ~= value then
		return false, "expecting "..value.." calls, actually "..#calls
	end
	return true
end