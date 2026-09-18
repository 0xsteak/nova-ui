local Theme = require(script.Parent.Parent.Parent.Classes.Theme)

return Theme.new('Dark', 'Nova', 'dark', {
	Background = Color3.fromHSV(0, 0, 0.1),
	Foreground = Color3.fromHSV(0, 0, 1),
	PrimaryText = Color3.fromHSV(0, 0, 1),
	SecondaryText = Color3.fromHSV(0, 0, 0.8),
	Accent = Color3.fromHSV(0.75, 0.75, 1),
})
