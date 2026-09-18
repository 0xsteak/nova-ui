local TypeUtils = require(script.Parent.Parent.Utils.TypeUtils)

export type BlueprintData<T = Instance> = {
	ClassName: string,
	[number]: BlueprintData | Instance,
} & TypeUtils.PropertiesTable<T>

type BlueprintProps = {
	ClassName: 'NovaUI.Blueprint',
	Data: BlueprintData,
}

local Blueprint = {}
Blueprint.__index = Blueprint

export type Blueprint = typeof(setmetatable({} :: BlueprintProps, Blueprint))

local function buildFromData(blueprintData: BlueprintData): Instance
	local instance = Instance.new(blueprintData.ClassName)

	for property, value in blueprintData do
		if property == 'ClassName' then
			continue
		end

		if typeof(property) == 'number' then
			if typeof(value) == 'table' then
				buildFromData(value).Parent = instance
			elseif typeof(value) == 'Instance' then
				value.Parent = instance
			end

			continue
		end

		instance[property] = value
	end

	return instance
end

function Blueprint.__tostring(self: Blueprint)
	return self.ClassName
end

function Blueprint.new(blueprintData: BlueprintData): Blueprint
	local self = setmetatable({}, Blueprint) :: Blueprint

	self.ClassName = 'NovaUI.Blueprint'
	self.Data = blueprintData

	return self
end

function Blueprint.Build(self: Blueprint): Instance
	return buildFromData(self.Data)
end

return Blueprint
