local Transition = require(script.Transition)

local TransitionService = {}

local TagCollection: { [string]: { [Transition.Transition]: true } } = {}

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
