require 'luaspec'
require 'luamock'

describe["a Mock"] = function()
	before = function()
		mock = Mock:new()
	end
	
	describe["when called as a function with no parameters"] = function()
		before = function()
			return_value = mock()
		end
		
		it["should return nil"] = function()
			expect(return_value).should_be(nil)
		end

		it["should record the call in Mock.calls"] = function()
			expect(#Mock.calls[mock]).should_be(1)
		end
		
		it["should record the parameters (or lack there of)"] = function()
			expect(#Mock.calls[mock][1]).should_be(0)
		end
		
		describe["when called a second time with a few parameters"] = function()
			before = function()
				mock(1, "two", 3)
			end

			it["should record the call in Mock.calls"] = function()
				expect(#Mock.calls[mock]).should_be(2)
			end

			it["should record the parameters"] = function()
				-- TODO, replace with a single matcher that compares an array
				-- e.g. expect(Mock.calls[mock][2]).should_be({ 1, "two", 3 })
				expect(#Mock.calls[mock][2]).should_be(3)
				expect(Mock.calls[mock][2][1]).should_be(1)
				expect(Mock.calls[mock][2][2]).should_be("two")
				expect(Mock.calls[mock][2][3]).should_be(3)
			end
		end
	end
	
	describe["when accessing a new property"] = function()
		before = function()
			field = mock.foo
		end
		
		it["should create a new Mock instance"] = function()
			expect(getmetatable(field)).should_be(Mock)
		end
	end
	
	describe["when setting a property"] = function()
		before = function()
			mock.foo = 25
		end
		
		it["should be accessible"] = function()
			expect(mock.foo).should_be(25)
		end
	end
	
	describe["when specifying a return value"] = function()
		before = function()
			mock:should_return(10)
		end
		
		it["should return that value when called as a function"] = function()
			expect(mock()).should_be(10)
		end
	end

	describe["when specifying a return value using . instead of :"] = function()
		before = function()
			err = track_error(function() mock.should_return(10) end)
		end
		
		it["should produce an error"] = function()
			expect(err).should_not_be(nil)
		end
	end
	
end