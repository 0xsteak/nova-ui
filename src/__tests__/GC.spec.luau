type factories = {
	[string]: () -> { unknown },
}

return function()
	local Nova = require(script.Parent.Parent)
	local Icon = require(script.Parent.Parent.Classes.Icon)
	local Button = require(script.Parent.Parent.Components.Buttons.Button)
	local IconButton = require(script.Parent.Parent.Components.Buttons.IconButton)
	local Container = require(script.Parent.Parent.Components.Container)
	local Label = require(script.Parent.Parent.Components.Label)
	local ScrollView = require(script.Parent.Parent.Components.ScrollView)
	local Window = require(script.Parent.Parent.Components.Window)
	local DragController = require(script.Parent.Parent.Controllers.DragController)
	local ResizeController = require(script.Parent.Parent.Controllers.ResizeController)
	local GridLayout = require(script.Parent.Parent.Layouts.GridLayout)
	local ListLayout = require(script.Parent.Parent.Layouts.ListLayout)
	local PageLayout = require(script.Parent.Parent.Layouts.PageLayout)
	local Transition = require(script.Parent.Parent.Services.TransitionService.Transition)
	local GcTracker = require(script.Parent.Parent.Utils.GcTracker)

	local OBJECT_FACTORIES: factories = {
		Window = function()
			local win = Window.new()
			local objects = { win, win.Base, win.Content, win.DragController, win.ResizeController }
			for _, button in win.TopBarButtons do
				table.insert(objects, button)
			end
			return objects
		end,
		Container = function()
			local cont = Container.new()
			local lout = ListLayout.new()
			cont:SetLayout(lout)
			local objects = { cont, cont.Base, cont.Layout }
			return objects
		end,
		Button = function()
			local btn = Button.new()
			local objects = { btn, btn.Base }
			return objects
		end,
		IconButton = function()
			local iconBtn = IconButton.new(Icon.empty)
			local objects = { iconBtn, iconBtn.Base, iconBtn.Button }
			for _, transGroup in iconBtn.TransitionGroups do
				table.insert(objects, transGroup)
			end
			return objects
		end,
		ScrollView = function()
			local sView = ScrollView.new()
			local objects = { sView, sView.Base }
			for _, transGroup in sView.TransitionGroups do
				table.insert(objects, transGroup)
			end
			return objects
		end,
		Label = function()
			local label = Label.new()
			local objects = { label, label.Base, label._params }
			return objects
		end,
		-- -- -- --
		DragController = function()
			local dummy = Instance.new('Frame')
			local drag = DragController.new(dummy, dummy)
			local objects = { drag }
			return objects
		end,
		ResizeController = function()
			local dummy = Instance.new('Frame')
			local resize = ResizeController.new(dummy, dummy)
			local objects = { resize }
			return objects
		end,
		-- -- -- --
		ListLayout = function()
			local list = ListLayout.new()
			local objects = { list, list.Base }
			return objects
		end,
		GridLayout = function()
			local grid = GridLayout.new()
			local objects = { grid, grid.Base }
			return objects
		end,
		PageLayout = function()
			local page = PageLayout.new()
			local objects = { page, page.Base }
			return objects
		end,
		-- -- -- --
		Transition = function()
			local dummy = Instance.new('Frame')
			local transition = Transition.new(dummy, {
				PropertyTable = {
					Size = UDim2.new(),
				},
				Time = 0.5,
			})
			return { transition, dummy }
		end,
	}

	Nova.Init()

	beforeAll(GcTracker.EnableMemoryPressure)
	afterAll(GcTracker.DisableMemoryPressure)

	local trackers = {}

	for objectName, objectFactory in OBJECT_FACTORIES do
		trackers[objectName] = {}
		local objects = objectFactory()
		for i, object in objects do
			assert(type(object) == 'table' or type(object) == 'userdata', `invalid object ({objectName}, #{i})`)

			trackers[objectName][i] = GcTracker.track(object)
			if object.Destroy then
				object:Destroy()
			end
		end
	end

	for objectName in OBJECT_FACTORIES do
		describe(objectName, function()
			local objectTrackers = trackers[objectName]
			local failed = false

			for i = 1, #objectTrackers do
				it(`should garbage collect object #{i}`, function()
					local tracker = objectTrackers[i]
					if not failed then
						local success = GcTracker.waitForGc(tracker, 5)
						failed = not success or failed
					end
					expect(tracker.value()).never.to.be.ok()
				end)
			end
		end)
	end
end
