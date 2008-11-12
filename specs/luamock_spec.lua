require 'luaspec'
require 'luamock'

describe["MockAccessor"] = function()
	it["can be created with a name and mock object"] = function()
		m = MockAccessor:new("a_name", {})
		expect(m).should_not_be(nil)
	end
end

describe["a newly created MockAccessor"] = function()

	before = function()
		name = "a_name"
		mock = {}
		m = MockAccessor:new(name, mock)
	end
	
	it["should set mock property"] = function()
		expect(m.mock).should_be(mock)
	end

	it["should set name property"] = function()
		expect(m.name).should_be(name)
	end
	
	it["when called as a function it should add an entry to the mock.__calls[name] array containing the parameters"] = function()
		mock.__calls = {}
		m(37)
		expect(#mock.__calls[name]).should_be(1)
		expect(#mock.__calls[name][1]).should_be(1)
		expect(mock.__calls[name][1][1]).should_be(37)
	end
end

describe["Mock"] = function()
	it["can be created"] = function()
		mock = Mock:new()
		expect(mock).should_not_be(nil)
	end
end

describe["a newly created Mock" ] = function()
	before = function()
		mock = Mock:new()
	end
	
	it["should have a __calls table"] = function()
		expect(type(mock.__calls)).should_be("table")
	end
end


describe["a Mock after mock.foo has been called"] = function()
	before = function()
		mock = Mock:new()
		mock.foo()
	end
	
	it["should have a __calls table with a foo entry"] = function()
		expect(type(mock.__calls.foo)).should_be("table")
	end
	
	it["should have a __calls table with a foo array with one entry"] = function()
		expect(#mock.__calls.foo).should_be(1)
	end
end

describe["was_called matcher"] = function()
	before = function()
		mock = Mock:new()
		mock.foo()
	end
	
	it["should return true when called with mock.foo, 1"] = function()
		expect(matchers.was_called(mock.foo, 1)).should_be(true)
	end
	
	it["should return false when called with mock.bar, 1"] = function()
		expect(matchers.was_called(mock.bar, 1)).should_be(false)
	end

	it["should work as a matcher"] = function()
		expect(mock.foo).was_called(1)
	end

	it["should return false when something other than a MockAccessory is passed in"] = function()
		expect(matchers.was_called({}, 1)).should_be(false)
	end		
end

