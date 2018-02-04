local timestats = {}

local function displaytime(time)
	return math.floor(time * 1000000 + 0.5) / 1000 .. " ms"
end

local function start(self, active)
	local t0 = os.clock()
	local n = #self + 1
	if active == false then
		self[n] = -0
	else
		self[n] = t0
	end
	return n
end

local function pause(self, n)
	local t1 = os.clock()
	n = n or #self
	local t0 = self[n]
	if t0 > 0 then
		self[n] = t0 - t1 -- Set to the time delta between both calls. Negative sign shows that the timer is paused.
	end
end

local function resume(self, n)
	local t2 = os.clock()
	n = n or #self
	local delta = self[n]
	if delta <= 0 then
		self[n] = t2 + delta
	end
end

local function stop(self, n)
	local t3 = os.clock()
	n = n or #self
	local t0 = self[n]
	local time
	if t0 > 0 then -- Counter was active so time is the diff between t0 and t3
		time = t3 - t0
	else
		time = -t0 -- If counter was inactive, t0 is the negative time delta
	end
	self.calls = self.calls + 1
	self.sum = self.sum + time
	self.sum2 = self.sum2 + time^2

	self[n] = nil

	if self.autoprint then
		print("[timestats] " .. self.name .. ": " .. displaytime(time))
	end
end

local function step(self, n)
	stop(self, n)
	return start(self)
end

local function stats(self)
	local mean = self.sum / self.calls
	local stdev = math.sqrt(self.sum2/self.calls - mean^2)
	return mean, stdev
end

local function printstats(self)
	local mean, stdev = stats(self)
	print("[timestats] " .. self.name .. ":")
	print("\tOperations: " .. self.calls)
	print("\tAverage time: " .. displaytime(mean))
	print("\tStandard dev: " .. displaytime(stdev))
end

local function endall(self)
	for n in pairs(self) do
		if type(n) == "number" then
			stop(self, n)
		end
	end
end

local mt = {
	start = start,
	pause = pause,
	resume = resume,
	stop = stop,
	step = step,
	stats = stats,
	printstats = printstats,
	endall = endall,
}
mt.__index = mt -- Index method will refer to the metatable itself
mt.__call = start

function TimeStats(name, autoprint)
	local obj = {
		name = name,
		calls = 0,
		sum = 0,
		sum2 = 0,
		autoprint = autoprint,
	}
	table.insert(timestats, obj)
	return setmetatable(obj, mt)
end

minetest.register_on_shutdown(function()
	for i, obj in ipairs(timestats) do
		endall(obj)
		if obj.autoprint then
			printstats(obj)
		end
	end
end)
