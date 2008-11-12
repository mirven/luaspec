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

function spec.add_results(success, message, trace)
	if spec.current.passed then
		spec.current.passed = success
	end

	if success then
		spec.passed = spec.passed + 1
	else
		table.insert(spec.current.errors , { message = message, trace = trace } )
		spec.failed = spec.failed + 1
	end
end

function spec.add_context(name)	
	spec.contexts[#spec.contexts+1] = name
	spec.contexts[name] = {}	
end

local pending = {}
local pending_mt = {}

function pending_mt.__newindex() error("You can't set properties on pending") end
function pending_mt.__index(_, key) 
	if key == "description" then 
		return nil 
	else
		error("You can't get properties on pending") 
	end
end
function pending_mt.__call(_, description)
	local o = { description = description}
	setmetatable(o, pending_mt)
	return o
end	


setmetatable(pending, pending_mt)


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
			
			spec.add_results(success, message, debug.traceback())
		end
	end})
	return t
end


-- function run_context(name, before, after, specs, sub_contexts)
function run_context(name, context, before_stack)
	before_stack = before_stack or {}
	
	local c = spec.contexts[name]
	
	for k, spec_func in pairs(context.specs) do
		
		if getmetatable(spec_func) == pending_mt then
			print(spec_func.description)
			print "pending, ignore"
		else
			c[k] = { passed = true, errors = {} }
			spec.current = c[k]
	
			-- setup the environment that the spec is run in, each spec is run in a new environment
			local env = {}
			setmetatable(env, { __index = _G })
		
			-- run all before's on enclosing contexts
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
	end
	
	before_stack[#before_stack+1] = context.before
	
	for n,c in pairs(context.sub_contexts) do
		run_context(n, c, before_stack)
	end
end

function create_context_env()

	local it, specs = make_it()
	local describe, sub_contexts = make_describe()

	-- create an environment to run the function in
	local context_env = {
		it = it,
		describe = describe,
		pending = pending
	}
	
	return context_env, sub_contexts, specs
end

function make_it()
	-- create and set metatables for 'it'
	local specs = {}
	local it = {}
	setmetatable(it, {
		-- this is called when it is assigned a function (e.g. it["spec name"] = function() ...)
		__newindex = function(_, spec_name, spec_function)
			specs[spec_name] = spec_function
		end
	})
	
	return it, specs
end

function make_describe(auto_run)
	local describe = {}
	local contexts = {}
	local describe_mt = {
		
		-- This function is called when a function is assigned to a describe table (e.g. describe["context name"] = function() ...)
		__newindex = function(_, context_name, context_function)
		
			spec.add_context(context_name)

			local context_env, sub_contexts, specs = create_context_env()
			
			-- set the environment
			setfenv(context_function, context_env)
			
			-- run the context function which collects the data into context_env and sub_contexts
			context_function()			
			
			-- store the describe function in contexts
			contexts[context_name] = { 
				before=context_env.before, 
				after=context_env.after, 
				specs=specs, 
				sub_contexts = sub_contexts 
			}
			
			if auto_run then
				run_context(context_name, contexts[context_name])
			end
		end
	}
	
	setmetatable(describe, describe_mt)
	
	return describe, contexts
end

describe = make_describe(true)
