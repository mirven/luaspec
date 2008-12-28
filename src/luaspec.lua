spec = {
  contexts = {}, passed = 0, failed = 0, pending = 0, current = nil
}

function spec:compute_report()
	local report = {		
		num_passed = self.passed,
		num_failed = self.failed,
		num_pending = self.pending,
		total = self.passed + self.failed + self.pending,
		results = {}
	}
	report.percent = self.passed/report.total*100
	
	local contexts = self.contexts
	
	for index = 1, #contexts do
		report.results[index] = {
			name = contexts[index],			
			spec_results = contexts[contexts[index]]
		}
	end		
	
	return report	
end

function spec:report(verbose)
	local report = self:compute_report()

	if report.num_failed == 0 and not verbose then
		print "all tests passed"
		return
	end
	
	for _, result in pairs(report.results) do
		print(("%s\n================================"):format(result.name))
		
		for description, r in pairs(result.spec_results) do
			local outcome = r.passed and 'pass' or "FAILED"

			if verbose or not (verbose and r.passed) then
				print(("%-70s [ %s ]"):format(" - " .. description, outcome))

				table.foreach(r.errors, function(index, error)
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

	print(summary:format(report.total, report.num_passed, report.num_failed, report.percent))
end

function spec:add_results(success, message, trace)
	if self.current.passed then
		self.current.passed = success
	end

	if success then
		self.passed = self.passed + 1
	else
		table.insert(self.current.errors , { message = message, trace = trace } )
		self.failed = self.failed + 1
	end
end

function spec:add_context(name)	
	self.contexts[#self.contexts+1] = name
	self.contexts[name] = {}	
end

function spec:add_spec(context_name, spec_name)
	local context = self.contexts[context_name]
	context[spec_name] = { passed = true, errors = {} }
	self.current = context[spec_name]
end

function spec:add_pending_spec(context_name, spec_name, pending_description)
end

-- create tables to support pending specifications
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

-- define matchers

matchers = {	
	should_be = function(value, expected)
		if value ~= expected then
			return false, "expecting "..tostring(expected)..", not ".. tostring(value)
		end
		return true
	end;

	should_not_be = function(value, expected)
		if value == expected then
			return false, "should not be "..tostring(value)
		end
		return true
	end;
	
	should_error = function(f)
		if pcall(f) then
			return false, "expecting an error but received none"
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

-- expect returns an empty table with a 'method missing' metatable
-- which looks up the matcher.  The 'method missing' function
-- runs the matcher and records the result in the current spec
local function expect(target)
	local t = {}
	setmetatable(t, { 
		__index = function(t, matcher)
			return function(...)
				local success, message = matchers[matcher](target, ...)
			
				spec:add_results(success, message, debug.traceback())
			end
		end
	})
	return t
end

local function run_context(context_name, context, before_stack, after_stack)

	before_stack = before_stack or {}
	after_stack = after_stack or {}
	
	-- run all of the context's specs
	for spec_name, spec_func in pairs(context.specs) do
		
		-- check to see if the spec is pending or not
		if getmetatable(spec_func) == pending_mt then
			spec:add_pending_spec(context_name, spec_name, spec_func.description)
		else
			spec:add_spec(context_name, spec_name)
			
			-- setup the environment that the spec is run in, each spec is run in a new environment
			local env = {
				track_error = function(f)
					local status, err = pcall(f)
					return err
				end,
				
				expect = expect
			}
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
			local success, message = pcall(spec_func)
			
			if context.after then
				setfenv(context.after, env)
				context.after()
			end
			
			-- run all afters's on enclosing contexts
			for i=#after_stack,1,-1 do
				local after = after_stack[i]
				setfenv(after, env)
				after()
			end
			
			
			if not success then
				spec:add_results(false, message, debug.traceback())
			end
		end
	end
	
	-- make a copy and update the before_stack and after_stack with current before and after and run sub-contexts
	local before_stack_copy = {}
	
	for i,v in ipairs(before_stack) do
		before_stack_copy[i] = v
	end
		
	before_stack_copy[#before_stack_copy+1] = context.before

	local after_stack_copy = {}
	
	for i,v in ipairs(after_stack_copy) do
		after_stack_copy[i] = v
	end
		
	after_stack_copy[#after_stack_copy+1] = context.after
	
	for subcontext_name, subcontext in pairs(context.sub_contexts) do
		run_context(subcontext_name, subcontext, before_stack_copy, after_stack_copy)
	end
end

local function make_it_table()
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

local make_describe_table

-- create an environment to run a context function in as well as the tables to collect 
-- the subcontexts and specs
local function create_context_env()
	local it, specs = make_it_table()
	local describe, sub_contexts = make_describe_table()

	-- create an environment to run the function in
	local context_env = {
		it = it,
		describe = describe,
		pending = pending
	}
	
	return context_env, sub_contexts, specs
end

-- Note: this is declared locally earlier so it is still local, not 100% sure why i can't redeclare it as local
function make_describe_table(auto_run)
	local describe = {}
	local contexts = {}
	local describe_mt = {
		
		-- This function is called when a function is assigned to a describe table 
		-- (e.g. describe["context name"] = function() ...)
		__newindex = function(_, context_name, context_function)
		
			spec:add_context(context_name)

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

describe = make_describe_table(true)