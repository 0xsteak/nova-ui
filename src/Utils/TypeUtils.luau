export type function PropertiesTable(instance: type)
	if not instance:is('extern') then
		error('bad argument, expected Instance')
	end

	local t = types.newtable()

	local function addPropertiesFrom(ty: type)
		for key, value in ty:properties() do
			if
				value.read and value.read:is('function')
				or value.write and value.write:is('function')
				or key:value() == 'WaitForChild'
			then
				continue
			end

			t:setreadproperty(key, value.read)
			t:setwriteproperty(key, value.write)
		end

		if ty:readparent() ~= nil then
			addPropertiesFrom(ty:readparent())
		end
	end

	addPropertiesFrom(instance)

	return t
end

export type function ClassName(instance: type)
	if not instance:is('extern') then
		error('bad argument, expected Instance')
	end

	for key, value in instance:properties() do
		if key:value() == 'ClassName' then
			return value.read
		end
	end

	return types.singleton('CLASS_NAME_NOT_FOUND')
end

export type function OptionalValues(t: type)
	if not t:is('table') then
		error(`invalid argument for optionalValues`)
	end

	local result = types.newtable()

	for key, value in t:properties() do
		local readValue = value.read

		if readValue then
			result:setproperty(key, types.optional(readValue))
		end
	end

	return result
end

return nil
