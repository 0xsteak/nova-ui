local Transition = require(script.Parent.Transition)

type TransitionGroupImpl = {
	__index: TransitionGroupImpl,
	__tostring: (self: TransitionGroup) -> 'NovaUI.TransitionGroup',
	new: (instances: { [string]: Instance }, preset: Preset) -> TransitionGroup,
	ReplayAll: (self: TransitionGroup) -> TransitionGroup,
	CancelAll: (self: TransitionGroup) -> TransitionGroup,
	ApplyAll: (self: TransitionGroup) -> TransitionGroup,
}

type self = {
	ClassName: 'NovaUI.TransitionGroup',
	Transitions: { [string]: Transition.Transition },
}

export type TransitionGroup = setmetatable<self, TransitionGroupImpl>

export type Preset = {
	_base: {
		Time: number,
		EasingStyle: Enum.EasingStyle?,
		EasingDirection: Enum.EasingDirection?,
		DelayTime: number?,
		RepeatCount: number?,
		Reverses: boolean?,
	}?,
	[string]: Transition.Preset,
}

local TransitionGroup = {} :: TransitionGroupImpl
TransitionGroup.__index = TransitionGroup

function TransitionGroup:__tostring(): 'NovaUI.TransitionGroup'
	return 'NovaUI.TransitionGroup'
end

function TransitionGroup.new(instances: { [string]: Instance }, preset: Preset): TransitionGroup
	local self: TransitionGroup = setmetatable({}, TransitionGroup)

	self.ClassName = 'TransitionGroup'
	self.Transitions = {}

	local _base = preset._base or {}

	for id, instance in instances do
		local transitionPreset = preset[id]

		assert(transitionPreset, `missing preset for "{id}"`)

		for i, v in _base do
			if transitionPreset[i] == nil then
				transitionPreset[i] = v
			end
		end

		local transition = Transition.new(instance, transitionPreset)
		self.Transitions[id] = transition
		transition.Destroying:Once(function()
			self.Transitions[id] = nil
		end)
	end

	return self
end

function TransitionGroup.ReplayAll(self: TransitionGroup)
	for _, transition in self.Transitions do
		transition:Replay()
	end
end

function TransitionGroup.CancelAll(self: TransitionGroup)
	for _, transition in self.Transitions do
		transition:Cancel()
	end
end

function TransitionGroup.ApplyAll(self: TransitionGroup)
	for _, transition in self.Transitions do
		transition:Apply()
	end
end

return TransitionGroup
