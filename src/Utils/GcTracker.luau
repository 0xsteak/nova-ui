local GcTracker = {}

type tracker<T = any> = {
	value: () -> T,
}

local memoryPressureEnabled = false

task.spawn(function()
	local memoryPressure = {}

	while true do
		if memoryPressureEnabled then
			if #memoryPressure > 50000 then
				table.clear(memoryPressure)
			end
			table.insert(memoryPressure, Instance.new('Part'))
		end
		task.wait()
	end
end)

function GcTracker.track<T>(target: T): tracker<T>
	local weakBox = setmetatable({}, { __mode = 'v' })
	weakBox[1] = target

	return {
		value = function()
			return weakBox[1]
		end,
	}
end

function GcTracker.EnableMemoryPressure()
	memoryPressureEnabled = true
end

function GcTracker.DisableMemoryPressure()
	memoryPressureEnabled = false
end

function GcTracker.waitForGc(tracker: tracker, timeout: number?): boolean
	timeout = timeout or 5
	local timeStart = tick()

	while true do
		if tick() - timeStart > timeout then
			break
		end
		if tracker.value() == nil then
			--print(`Triggered gc in {tick() - timeStart}s`)
			return true
		end
		task.wait()
	end

	return false
end

return GcTracker
