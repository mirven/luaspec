require 'luaspec'
require 'mock'

describe "MockAccess" {
	["can be created with a name and mock object"] = function()
		m = MockAccess:new("a_name", {})
		expect(m).should_not_be(nil)
	end;
}

describe "a newly created MockAccess" {

	before = function()
		name = "a_name"
		mock = {}
		m = MockAccess:new(name, mock)
	end;
	
	["should set mock property"] = function()
		expect(m.mock).should_be(mock)
	end;

	["should set name property"] = function()
		expect(m.name).should_be(name)
	end;
	
	["when called as a function it should add an entry to the mock.__calls[name] array containing the parameters"] = function()
		mock.__calls = {}
		m(37)
		expect(#mock.__calls[name]).should_be(1)
		expect(#mock.__calls[name][1]).should_be(1)
		expect(mock.__calls[name][1][1]).should_be(37)
	end;
}

describe "Mock" {
	["can be created"] = function()
		mock = Mock:new()
		expect(mock).should_not_be(nil)
	end;
}

describe "a newly created Mock" {
	before = function()
		mock = Mock:new()
	end;
	
	["should have a __calls table"] = function()
		expect(type(mock.__calls)).should_be("table")
	end;
}

describe "a Mock after mock.foo has been called" {
	before = function()
		mock = Mock:new()
		mock.foo()
	end;
	
	["should have a __calls table with a foo entry"] = function()
		expect(type(mock.__calls.foo)).should_be("table")
	end;
	
	["should have a __calls table with a foo array with one entry"] = function()
		expect(#mock.__calls.foo).should_be(1)
	end;
}


spec.report(true)