local Transition = require(script.Parent.Transition)

type TransitionGroupProps = {
	Transitions: { [string]: Transition.Transition },
}

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

local TransitionGroup = {}
TransitionGroup.__index = TransitionGroup

TransitionGroup.ClassName = 'NovaUI.TransitionGroup'

export type TransitionGroup = typeof(setmetatable({} :: TransitionGroupProps, TransitionGroup))

function TransitionGroup:__tostring()
	return TransitionGroup.ClassName
end

function TransitionGroup.new(targets: { [string]: Instance }, preset: Preset): TransitionGroup
	local self: TransitionGroup = setmetatable({}, TransitionGroup)

	self.Transitions = {}

	local _base = preset._base or {}

	for id, target in targets do
		local transitionPreset = preset[id]

		assert(transitionPreset, `missing preset for "{id}"`)

		for i, v in _base do
			if transitionPreset[i] == nil then
				transitionPreset[i] = v
			end
		end

		local transition = Transition.new(target, transitionPreset)
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

function TransitionGroup.Destroy(self: TransitionGroup)
	for _, transition in self.Transitions do
		transition:Destroy()
	end
	table.clear(self.Transitions)
end

return TransitionGroup
