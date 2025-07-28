local Theme = require("../../Classes/Theme")

-- -- -- -- --

return {
    Theme.new("Dark", "Nova", false, {
        Background = Color3.fromHSV(0, 0, 0.1),
        PrimaryText = Color3.fromHSV(0, 0, 1),
        SecondaryText = Color3.fromHSV(0, 0, 0.8),
        PrimaryIcon = Color3.fromHSV(0, 0, 1),
        SecondaryIcon = Color3.fromHSV(0, 0, 0.8),
        Highlight = Color3.fromHSV(0.75, 0.6, 1),
        IconButtonHover = Color3.fromHSV(0, 0, 0.15),
        IconButtonDown = Color3.fromHSV(0, 0, 0.125),
        ScrollBarTrack = Color3.fromHSV(0, 0, 0.7),
        ScrollBarThumb = Color3.fromHSV(0, 0, 0.7)
    }),
    Theme.new("Light", "Nova", false, {
        Background = Color3.fromHSV(0, 0, 0.9),
        PrimaryText = Color3.fromHSV(0, 0, 0),
        SecondaryText = Color3.fromHSV(0, 0, 0.2),
        PrimaryIcon = Color3.fromHSV(0, 0, 0),
        SecondaryIcon = Color3.fromHSV(0, 0, 0.2),
        Highlight = Color3.fromHSV(0.75, 0.6, 1),
        IconButtonHover = Color3.fromHSV(0, 0, 0.95),
        IconButtonDown = Color3.fromHSV(0, 0, 0.925),
        ScrollBarTrack = Color3.fromHSV(0, 0, 0.3),
        ScrollBarThumb = Color3.fromHSV(0, 0, 0.3)
    })
} :: {Theme.Theme}