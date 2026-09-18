local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Jest = require(ReplicatedStorage.Nova.Packages.Jest)

local processServiceExists, ProcessService = pcall(function()
	return game:GetService('ProcessService' :: string)
end)

local status, result = Jest.runCLI(ReplicatedStorage.Nova, {
	ci = false,
	verbose = false,
}, { ReplicatedStorage.Nova }):awaitStatus()

if status == 'Rejected' then
	print(result)
end

if status == 'Resolved' and result.results.numFailedTestSuites == 0 and result.results.numFailedTests == 0 then
	if processServiceExists then
		ProcessService:ExitAsync(0)
	end
end

if processServiceExists then
	ProcessService:ExitAsync(1)
end

return nil
