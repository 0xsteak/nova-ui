local TypeUtils = require(script.Parent.Parent.Parent.Utils.TypeUtils)
local TweenService = game:GetService('TweenService')
local Promise = require(script.Parent.Parent.Parent.Packages.Promise)
local Preferences = require(script.Parent.Parent.Parent.Registry.Preferences)

type targetMap = { [Instance]: PropertyTable }

type TransitionProps = {
	TargetMap: targetMap,
	PlaybackState: Enum.PlaybackState,
	_tweenInfo: TweenInfo,
	_tweens: { Tween },
}

export type PropertyTable<T = Instance> = TypeUtils.PropertiesTable<T> | () -> TypeUtils.PropertiesTable<T>
export type pt<T> = PropertyTable<T>

local Transition = {}
Transition.__index = Transition

Transition.ClassName = 'NovaUI.Transition'

export type Transition = typeof(setmetatable({} :: TransitionProps, Transition))

function Transition:__tostring()
	return Transition.ClassName
end

local function getPropertyTable(propertyTable: PropertyTable)
	if typeof(propertyTable) == 'table' then
		return propertyTable
	else
		return propertyTable()
	end
end

function Transition.new(targetMap: targetMap, tweenInfo: TweenInfo): Transition
	local self: Transition = setmetatable({}, Transition)

	self.TargetMap = targetMap
	self._tweens = {}
	self._tweenInfo = tweenInfo
	self.PlaybackState = Enum.PlaybackState.Begin

	for target in targetMap do
		target.Destroying:Once(function()
			targetMap[target] = nil
		end)
	end

	return self
end

function Transition.Play(self: Transition)
	return Promise.new(function(resolve)
		self:Cancel()

		if not Preferences.GetTransitionsEnabled() then
			self:Apply()
			resolve()
			return
		end

		local tweens: { Tween } = {}

		for target, propertyTable in self.TargetMap do
			table.insert(tweens, TweenService:Create(target, self._tweenInfo, getPropertyTable(propertyTable)))
		end

		local lastTween = tweens[#tweens]

		local connection = lastTween:GetPropertyChangedSignal('PlaybackState'):Connect(function()
			self.PlaybackState = lastTween.PlaybackState
		end)

		for _, tween in tweens do
			tween:Play()
		end

		lastTween.Completed:Once(function()
			connection:Disconnect()
			self._tweens = {}
			resolve()
		end)

		self._tweens = tweens
	end)
end

function Transition.Pause(self: Transition)
	if self.PlaybackState ~= Enum.PlaybackState.Playing then
		return
	end

	for _, tween in self._tweens do
		tween:Pause()
	end
end

function Transition.Resume(self: Transition)
	if self.PlaybackState ~= Enum.PlaybackState.Paused then
		return
	end

	for _, tween in self._tweens do
		tween:Play()
	end
end

function Transition.Cancel(self: Transition)
	for _, tween in self._tweens do
		tween:Cancel()
	end
end

function Transition.Apply(self: Transition)
	self:Cancel()

	for target, propertyTable in self.TargetMap do
		for property, value in getPropertyTable(propertyTable) do
			target[property] = value
		end
	end

	self.PlaybackState = Enum.PlaybackState.Completed
end

function Transition.Destroy(self: Transition)
	self:Cancel()
	self.TargetMap = {}
end

return Transition
