local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TestEZ = require(ReplicatedStorage.Nova.Packages.TestEZ)

TestEZ.TestBootstrap:run({ ReplicatedStorage.Nova.__tests__ })
