require 'luaspec'
require 'stack'

describe["A Stack"] = function()
	before = function()
		s = Stack:new()
	end
	
	it["should be empty to start with"] = function()
		expect(s:top()).should_be(nil)
	end
	
	it["should allow items to be pushed"] = function()
		s:push(30)
		expect(s:top()).should_be(30)
	end
	
	it["this is pending"] = pending--("we're done")
end

