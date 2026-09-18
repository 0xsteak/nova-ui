local Signal = require(script.Parent.Parent.Parent.Packages.Signal)
local TypeUtils = require(script.Parent.Parent.Parent.Utils.TypeUtils)
local TweenService = game:GetService('TweenService')
local Preferences = require(script.Parent.Parent.Parent.Registry.Preferences)

type TransitionImpl = {
	__index: TransitionImpl,
	__tostring: (self: Transition) -> 'NovaUI.Transition',
	new: (instance: Instance, preset: Preset) -> Transition,
	Play: (self: Transition) -> (),
	Replay: (self: Transition) -> (),
	Pause: (self: Transition) -> (),
	Cancel: (self: Transition) -> (),
	Apply: (self: Transition) -> (),
	Destroy: (self: Transition) -> (),
}

type self = {
	ClassName: 'NovaUI.Transition',
	Instance: Instance?,
	TweenInfo: TweenInfo,
	PropertyTable: PropertyTable,
	Completed: Signal.Signal<Enum.PlaybackState>,
	PlaybackState: Enum.PlaybackState,
	Destroying: Signal.Signal<>,
	_tween: Tween?,
	_completedConnection: RBXScriptConnection?,
}

export type PropertyTable<T = Instance> = TypeUtils.PropertiesTable<T> | () -> TypeUtils.PropertiesTable<T>

export type Preset<T = Instance> = {
	PropertyTable: PropertyTable<T>,
	Time: number,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
	DelayTime: number?,
	RepeatCount: number?,
	Reverses: boolean?,
}

export type Transition = setmetatable<self, TransitionImpl>

local Transition = {} :: TransitionImpl
Transition.__index = Transition

function Transition:__tostring(): 'NovaUI.Transition'
	return 'NovaUI.Transition'
end

local function getPropertyTable(propertyTable: PropertyTable)
	return if typeof(propertyTable) == 'function' then propertyTable() else propertyTable
end

local function initTween(self: Transition): Tween
	local tween = TweenService:Create(self.Instance, self.TweenInfo, getPropertyTable(self.PropertyTable))

	self._tween = tween
	self.PlaybackState = Enum.PlaybackState.Begin

	self._completedConnection = tween.Completed:Connect(function(playbackState)
		self.PlaybackState = playbackState
		self.Completed:Fire(playbackState)
	end)

	return tween
end

function Transition.new(instance: Instance, preset: Preset): Transition
	local self: Transition = setmetatable({}, Transition)

	local tweenInfo = TweenInfo.new(
		preset.Time,
		preset.EasingStyle or Enum.EasingStyle.Quad,
		preset.EasingDirection or Enum.EasingDirection.Out,
		preset.RepeatCount or 0,
		preset.Reverses or false,
		preset.DelayTime or 0
	)

	self.ClassName = 'Transition'
	self.Instance = instance
	self.TweenInfo = tweenInfo
	self.PropertyTable = preset.PropertyTable
	self.Completed = Signal.new()
	self.PlaybackState = Enum.PlaybackState.Begin
	self.Destroying = Signal.new()

	instance.Destroying:Once(function()
		self:Destroy()
	end)

	return self
end

function Transition.Play(self: Transition)
	if not self.Instance then
		return
	end

	if not Preferences.GetTransitionsEnabled() then
		self:Apply()
		return
	end

	local tween = self._tween

	if not tween then
		tween = initTween(self)
	end

	tween:Play()
	self.PlaybackState = Enum.PlaybackState.Playing
end

function Transition.Replay(self: Transition)
	if not Preferences.GetTransitionsEnabled() then
		self:Apply()
		return
	end

	self:Cancel()
	self:Play()
end

function Transition.Pause(self: Transition)
	local tween = self._tween

	if tween then
		tween:Pause()
		self.PlaybackState = Enum.PlaybackState.Paused
	end
end

function Transition.Cancel(self: Transition)
	local tween = self._tween
	local completedConnection = self._completedConnection

	if tween then
		tween:Cancel()
		self._tween = nil
	end

	if completedConnection then
		completedConnection:Disconnect()
		self._completedConnection = nil
	end

	self.PlaybackState = Enum.PlaybackState.Cancelled
end

function Transition.Apply(self: Transition)
	local instance = self.Instance
	if not instance then
		return
	end

	self:Cancel()

	for property, value in getPropertyTable(self.PropertyTable) do
		instance[property] = value
	end

	self.PlaybackState = Enum.PlaybackState.Completed
	self.Completed:Fire(Enum.PlaybackState.Completed)
end

function Transition.Destroy(self: Transition)
	self.Destroying:FireSync()
	self.Instance = nil
	Transition:Cancel()
end

return Transition
