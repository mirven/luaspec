require 'luaspec'
require 'stack'

function matchers.should_be_cool(value, expected1, expected2) 
	print("cool", expected1, expected2)
	-- return true
	return false, "not cool"
end

describe "A Stack" {

	before = function()
		s = Stack:new()
	end;
	
	["should be empty to start with"] = function()
		expect(s:top()).should_be(nil)
	end;
	
	["should allow items to be pushed"] = function()
		s:push(30)
		expect(s:top()).should_be(30)
		expect(s:top()).should_be_cool(20, 21)
	end;
}

spec.report(true)