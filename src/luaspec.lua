spec = {
  contexts = {}, passed = 0, failed = 0, current = nil
}

function spec.report(verbose)
	local total = spec.passed + spec.failed
	local percent = spec.passed/total*100
	local contexts = spec.contexts

	if spec.failed == 0 and not verbose then
		print "all tests passed"
		return
	end

	-- HACK: preserve hash ordering
	for index = 1, #contexts do
		local context, cases = contexts[index], contexts[contexts[index]]
		print(("%s\n================================"):format(context))

		for description, result in pairs(cases) do
			local outcome = result.passed and 'pass' or "FAILED"

			if verbose or not (verbose and result.passed) then
				print(("%-70s [ %s ]"):format(" - " .. description, outcome))

				table.foreach(result.errors, function(index, error)
					print("   ".. index..". Failed expectation : ".. error.message.."\n   "..error.trace)
				end)
			end
		end
	end

	local summary = [[
=========  Summary  ============
%s Expectations
Passed : %s, Failed : %s, Success rate : %.2f percent
]]

	print(summary:format(total, spec.passed, spec.failed, percent))
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


-- function run_context(name, before, after, specs, sub_contexts)
function run_context(name, context, before_stack)
	before_stack = before_stack or {}
	
	local c = spec.contexts[name]
	
	for k, spec_func in pairs(context.specs) do
		c[k] = { passed = true, errors = {} }
		spec.current = c[k]
	
		-- setup the environment that the spec is run in, each spec is run in a new environment
		local env = {}
		setmetatable(env, { __index = _G })
		
		for _, before in ipairs(before_stack) do
			setfenv(before, env)
			before()
		end
		
		if context.before then
			setfenv(context.before, env)
			context.before()
		end

		setfenv(spec_func, env)
		spec_func()			
	end
	
	before_stack[#before_stack+1] = context.before
	
	for n,c in pairs(context.sub_contexts) do
		run_context(n, c, before_stack)
	end
end

function create_context_env()
	-- create an environment to run the function in
	local context_env = {
		it = {},
		describe = {}
	}

	-- create and set metatables for 'it'
	local specs = {}
	setmetatable(context_env.it, {
		__newindex = function(t, k, v)
			specs[k] = v
		end
	})

	-- and for 'describe'
	local mt, sub_contexts = make_describe_mt()
	setmetatable(context_env.describe, mt)
	
	return context_env, sub_contexts, specs
end

function make_describe_mt(auto_run)
	local contexts = {}
	local describe_mt = {
		__newindex = function(t, k, v)
		
			spec.contexts[#spec.contexts+1] = k
			spec.contexts[k] = {}

			local context_env, sub_contexts, specs = create_context_env()
			
			-- set the environment
			setfenv(v, context_env)
			
			-- run the context function which collects the data into context_env and sub_contexts
			v()			
			
			-- store the describe function in contexts
			contexts[k] = { before=context_env.before, after=context_env.after, specs=specs, sub_contexts = sub_contexts }
			
			if auto_run then
				run_context(k, contexts[k])
			end
		end
	}
	return describe_mt, contexts
end

describe = {}

describe_mt, contexts = make_describe_mt(true)
setmetatable(describe, describe_mt)

-- --
-- require 'stack'
-- 
-- describe["A Stack"] = function()
-- 	before = function()
-- 		s = Stack:new()
-- 	end
-- 	
-- 	it["should be empty to start with"] = function()
-- 		expect(s:top()).should_be(nil)
-- 	end
-- 	
-- 	it["should allow items to be pushed"] = function()
-- 		s:push(30)
-- 		expect(s:top()).should_be(30)
-- 	end
-- end
-- 
-- describe["Another Stack"] = function()
-- 	before = function()
-- 		s = Stack:new()
-- 	end
-- 	
-- 	describe["a Sub Stack"] = function()
-- 		before = function()
-- 			-- s = Stack:new()
-- 		end
-- 
-- 		it["--should be empty to start with"] = function()
-- 			-- expect(s:top()).should_be(nil)
-- 		end
-- 
-- 		it["--should allow items to be pushed"] = function()
-- 			-- s:push(30)
-- 			-- expect(s:top()).should_be(30)
-- 		end
-- 	end
-- 	
-- 	it["should be empty to start with-"] = function()
-- 		-- expect(s:top()).should_be(nil)
-- 	end
-- 	
-- 	it["should allow items to be pushed-"] = function()
-- 		-- s:push(30)
-- 		-- expect(s:top()).should_be(30)
-- 	end
-- end
-- 
-- spec.report(true)
-- -- run_context(k, context_env.before, context_env.after, specs, sub_contexts)