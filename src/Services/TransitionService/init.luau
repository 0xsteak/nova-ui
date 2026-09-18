local Transition = require(script.Transition)
local TransitionGroup = require(script.TransitionGroup)

local TransitionService = {}

local TagCollection: { [string]: { [Transition.Transition]: true } } = {}

function TransitionService.Create(
	instance: Instance,
	preset: Transition.Preset,
	tags: { string }?
): Transition.Transition
	local transition = Transition.new(instance, preset)

	for _, tag in tags or {} do
		TransitionService.AddTag(transition, tag)
	end

	return transition
end

function TransitionService.CreateGroup(
	instances: { [string]: Instance },
	preset: TransitionGroup.Preset,
	tags: { string }?
): TransitionGroup.TransitionGroup
	local transitionGroup = TransitionGroup.new(instances, preset)

	for _, tag in tags or {} do
		for _, transition in transitionGroup.Transitions do
			TransitionService.AddTag(transition, tag)
		end
	end

	return transitionGroup
end

function TransitionService.AddTag(transition: Transition.Transition, tag: string)
	local tagged = TagCollection[tag]

	if not tagged then
		tagged = setmetatable({}, { __mode = 'k' })
		TagCollection[tag] = tagged
	end

	tagged[transition] = true
end

function TransitionService.RemoveTag(transition: Transition.Transition, tag: string)
	local tagged = TagCollection[tag]

	if not tagged then
		return
	end

	tagged[transition] = nil
end

function TransitionService.ApplyByTag(tag: string, onlyIfPlaying: boolean?)
	local tagged = TagCollection[tag]

	if not tagged then
		return
	end

	for transition in tagged do
		if onlyIfPlaying and transition.PlaybackState ~= Enum.PlaybackState.Playing then
			continue
		end

		transition:Apply()
	end
end

return TransitionService
