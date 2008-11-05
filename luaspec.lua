spec = {
  contexts = {}, passed = 0, failed = 0, current = nil
}

function describe(name)
	-- Hack reserve hash ordering
	spec.contexts[#spec.contexts+1] = name
	spec.contexts[name] = {}
	local context = spec.contexts[name]

	return function(specification) 
		local before = specification.before
		specification.before = nil
		
		for name, spec_func in pairs(specification) do
			context[name] = { passed = true, errors = {} }
			spec.current = context[name]
		      
			local env = {}
			setmetatable(env, { __index = _G })
			if before then
				setfenv(before, env)
				before()
			end
		
			setfenv(spec_func, env)
			spec_func()
		end		
	end
end

spec.report = function(verbose)
  local total = spec.passed + spec.failed
  local percent = spec.passed/total*100
  local contexts = spec.contexts
  local summery
  
  if spec.failed == 0 and not verbose then
    print "all tests passed"
    return
  end
  
  -- HACK: preserve hash ordering
  for index = 1, #contexts do
    local context, cases = contexts[index], contexts[contexts[index]]
    print (("%s\n================================"):format(context))
    
    for description, result in pairs(cases) do
      local outcome = result.passed and 'pass' or "FAILED"

      if verbose or not (verbose and result.passed) then
        print(("%-70s [ %s ]"):format(" - " .. description, outcome))

        table.foreach(result.errors, function(index, error)
          print ("   ".. index..". Failed expectation : ".. error.message.."\n   "..error.trace)
        end)
      end
    end
  end
  
  summery = [[
=========  Summery  ============
  %s Expectations
    Passed : %s, Failed : %s, Success rate : %.2f percent
  ]]
  
  print (summery:format(total, spec.passed, spec.failed, percent))
end

matchers = {	
	should_be = function(value, expected)
		if value ~= expected then
			return false, "expecting "..tostring(expected)..", not ".. tostring(value)
		end
			return true
	end;

	should_not_be = function(value, expected)
		if value == expected then
			return false, "should not be "..value
		end
		return true
	end;

	should_match = function(value, pattern) 
		if type(value) ~= 'string' then
			return false, "type error, should_match expecting target as string"
		end

		if not string.match(value, pattern) then
			return false, value .. "doesn't match pattern "..pattern
		end
		return true
	end;  
}
 
matchers.should_equal = matchers.should_be

function expect(target)
	local t = {}
	setmetatable(t, { __index = function(t, matcher)
		return function(...)
			local success, message = matchers[matcher](target, ...)
			
			if spec.current.passed then
				spec.current.passed = success
			end

			if success then
				spec.passed = spec.passed + 1
			else
				table.insert(spec.current.errors , { message = message, trace = debug.traceback() } )
				spec.failed = spec.failed + 1
			end
		end
	end})
	return t
end
