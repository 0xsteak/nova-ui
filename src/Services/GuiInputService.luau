local Signal = require(script.Parent.Parent.Packages.Signal)
local GuiUtils = require(script.Parent.Parent.Utils.GuiUtils)
local TypeUtils = require(script.Parent.Parent.Utils.TypeUtils)
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')

type ObjData = {
	Options: Options,
	Events: TypeUtils.OptionalValues<GuiEvents>,
	Connections: { RBXScriptConnection },
}

type ObjRegistry = {
	[GuiObject]: ObjData,
}

type GuiEvents = {
	InputBegan: Signal.Signal<InputObject>,
	InputChanged: Signal.Signal<InputObject>,
	InputEnded: Signal.Signal<InputObject>,
	MouseEnter: Signal.Signal<>,
	MouseMoved: Signal.Signal<>,
	MouseLeave: Signal.Signal<>,
	MouseButton1Down: Signal.Signal<>,
	MouseButton1Up: Signal.Signal<>,
	MouseButton1Click: Signal.Signal<>,
}

export type Options = {
	RequireOnTop: {
		IgnoreDescendants: boolean?,
		--- A list of ignored objects
		IgnoreList: { GuiObject }?,
		--- Called for each UI object that is visually above the target.
		--- Should return `true` if the object should be considered a blocking element,
		--- or `false` to ignore it.
		Filter: (candidate: GuiObject) -> boolean,
	} | true,
}

local GuiInputService = {}

local lastGuiInteraction = time()
local ecoMode = false

local CurrentlyHovered: { GuiObject } = {}
local GuiStorage: BasePlayerGui = GuiUtils.GetStorage()

local ObjRegistry: ObjRegistry = {}

local IsMouseOn: { [GuiObject]: boolean? } = setmetatable({}, { __mode = 'k' })

local function update()
	local guiInset = GuiService:GetGuiInset()

	local mouseLocation = UserInputService:GetMouseLocation()
	mouseLocation = Vector2.new(mouseLocation.X, mouseLocation.Y)
	mouseLocation -= guiInset

	CurrentlyHovered = GuiStorage:GetGuiObjectsAtPosition(mouseLocation.X, mouseLocation.Y)

	if #CurrentlyHovered > 0 then
		lastGuiInteraction = time()
		ecoMode = false
	end
end

local function isOnTop(object: GuiObject, requireOnTop: index<Options, 'RequireOnTop'>): boolean
	if requireOnTop == true then
		return CurrentlyHovered[1] == object
	end

	local ignoreDescendants = requireOnTop.IgnoreDescendants
	local ignoreList = requireOnTop.IgnoreList
	local filter = requireOnTop.Filter

	for i = 1, #CurrentlyHovered do
		local candidate = CurrentlyHovered[i]

		if candidate == object then
			return true
		end

		if ignoreDescendants and candidate:IsDescendantOf(object) then
			continue
		end
		if ignoreList and table.find(ignoreList, candidate) then
			continue
		end
		if filter and filter(candidate) == false then
			continue
		end

		return false
	end

	return false
end

local function addConnection(object: GuiObject, connection: RBXScriptConnection)
	if not ObjRegistry[object] then
		GuiInputService.Register(object)
	end

	table.insert(ObjRegistry[object].Connections, connection)
end

local function getOptions(object: GuiObject): Options?
	local objData = ObjRegistry[object]
	if not objData then
		return nil
	end

	return objData.Options
end

local function getRequireOnTop(object: GuiObject): index<Options, 'RequireOnTop'>?
	local options = getOptions(object)
	if not options then
		return nil
	end

	return options.RequireOnTop
end

local function basicWrap(
	object: GuiObject,
	event: RBXScriptSignal,
	numArgs: number?,
	extraCondition: (...any) -> boolean,
	isForeignEvent: boolean?
): Signal.Signal<...any>
	local signal = Signal.new()

	local connection = event:Connect(function(...)
		if extraCondition and not extraCondition(...) then
			return
		end
		local requireOnTop = getRequireOnTop(object)
		if requireOnTop and not isOnTop(object, requireOnTop) then
			return
		end

		if numArgs and numArgs ~= 0 then
			signal:Fire(select(numArgs, ...))
		else
			signal:Fire()
		end
	end)

	if isForeignEvent then
		addConnection(object, connection)
	end

	return signal
end

local function inputBegan(object: GuiObject, options: Options): Signal.Signal<InputObject>
	return basicWrap(object, object.InputBegan, 1)
end

local function inputChanged(object: GuiObject, options: Options): Signal.Signal<InputObject>
	return basicWrap(object, object.InputChanged, 1)
end

local function inputEnded(object: GuiObject, options: Options): Signal.Signal<InputObject>
	return basicWrap(object, object.InputEnded, 1)
end

local function mouseEnter(object: GuiObject): Signal.Signal<>
	local signal = Signal.new()

	local connection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local requireOnTop = getRequireOnTop(object)
		if requireOnTop and not isOnTop(object, requireOnTop) then
			return
		end
		if not IsMouseOn[object] then
			signal:Fire()
			IsMouseOn[object] = true
		end
	end)

	addConnection(object, connection)

	return signal
end

local function mouseMoved(object: GuiObject, options: Options): Signal.Signal<>
	return basicWrap(object, object.InputChanged, 0, function(input: InputObject)
		return input.UserInputType == Enum.UserInputType.MouseMovement
	end)
end

local function mouseLeave(object: GuiObject, options: Options): Signal.Signal<>
	local signal = Signal.new()

	local connection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local requireOnTop = getRequireOnTop(object)
		if isOnTop(object, requireOnTop) then
			return
		end
		if IsMouseOn[object] then
			signal:Fire()
			IsMouseOn[object] = false
		end
	end)

	addConnection(object, connection)

	return signal
end

local function mouseButton1Down(object: GuiObject, options: Options)
	return basicWrap(object, object.InputBegan, 0, function(input: InputObject)
		return input.UserInputType == Enum.UserInputType.MouseButton1
	end)
end

local function mouseButton1Up(object: GuiObject, options: Options)
	return basicWrap(object, UserInputService.InputEnded, 0, function(input: InputObject)
		return input.UserInputType == Enum.UserInputType.MouseButton1
	end, true)
end

local function mouseButton1Click(object: GuiObject, options: Options)
	local signal = Signal.new()

	object.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local requireOnTop = getRequireOnTop(object)
		if requireOnTop and not isOnTop(object, requireOnTop) then
			return
		end

		local c
		c = input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then
				return
			end
			c:Disconnect()
			if requireOnTop and not isOnTop(object, requireOnTop) then
				return
			end

			signal:Fire()
		end)
	end)

	return signal
end

local EventEmiters: { [keyof<GuiEvents>]: any } = {
	InputBegan = inputBegan,
	InputChanged = inputChanged,
	InputEnded = inputEnded,
	MouseEnter = mouseEnter,
	MouseMoved = mouseMoved,
	MouseLeave = mouseLeave,
	MouseButton1Down = mouseButton1Down,
	MouseButton1Up = mouseButton1Up,
	MouseButton1Click = mouseButton1Click,
}

function GuiInputService.Register(object: GuiObject, options: Options)
	assert(not ObjRegistry[object], 'The object is already registered')

	local data: ObjData = {
		Options = options,
		Events = {},
		Connections = {},
	}

	ObjRegistry[object] = data

	object.Destroying:Once(function()
		for _, signal in data.Events do
			signal = signal :: Signal.Signal<...any>

			signal:DisconnectAll()
		end
		for _, connection in data.Connections do
			connection:Disconnect()
		end

		ObjRegistry[object] = nil
	end)
end

function GuiInputService.AddEvent(object: GuiObject, event: keyof<GuiEvents>): Signal.Signal<...any>
	local objData = assert(ObjRegistry[object], 'Object is not registered, register it using GuiInputService.Register')
	local events = objData.Events
	local eventEmitter = EventEmiters[event]

	assert(eventEmitter, 'Invalid event name')

	if event == 'MouseEnter' or event == 'MouseLeave' then
		if not events.MouseEnter then
			events.MouseEnter = EventEmiters.MouseEnter(object)
		end
		if not events.MouseLeave then
			events.MouseLeave = EventEmiters.MouseLeave(object)
		end
		return events[event]
	end

	if not events[event] then
		events[event] = eventEmitter(object)
	end

	return events[event]
end

function GuiInputService.GetEvents(object: GuiObject): GuiEvents
	local objData = assert(ObjRegistry[object], 'Object is not registered, register it using GuiInputService.Register')
	return objData.Events
end

function GuiInputService.SetOptions(object: GuiObject, options: Options)
	local objData = assert(ObjRegistry[object], 'Object is not registered, register it using GuiInputService.Register')

	objData.Options = options
end

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and not ecoMode then
		update()
		if time() - lastGuiInteraction > 30 then
			ecoMode = true
		end
	end
end)

task.spawn(function()
	while task.wait(1) do
		if ecoMode then
			update()
		end
	end
end)

return GuiInputService
