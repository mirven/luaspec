require 'luaspec'

describe "default matchers" {
	["All matchers should be functions"] = function()
		for _, m in pairs(matchers) do
			expect(type(m)).should_be("function")
		end
	end;
}

spec.report(true)