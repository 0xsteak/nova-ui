type Tweener = {
    Tween: (object: Instance, tweenInfo: TweenInfo, id: string, propertyTable: {[string]: any}, autoPlay: boolean?) -> Tween,
    Stop: (object: Instance, id: string) -> (),
    StopColorTweens: () -> (),
    TweenInfo: (duration: number, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?, repeatCount: number?, reverses: boolean?, delayTime: number?) -> TweenInfo
}

export type TweenOptions = {
    Object: Instance,
    TweenInfo: TweenInfo,
    ID: string,
    PropertyTable: {[string]: any}
}

-- -- -- -- --

local Tweener = {} :: Tweener

local TweenService = game:GetService("TweenService")

local DEFAULT_EASING_STYLE = Enum.EasingStyle.Quad
local DEFAULT_EASING_DIRECTION = Enum.EasingDirection.Out

local tweens: {[Instance]: {[string]: any}} = {}
local colorTweens: {Tween} = {}

function Tweener.Tween(object, tweenInfo, id, propertyTable, autoPlay): Tween
    autoPlay = if autoPlay == nil then true else autoPlay

    local tween = TweenService:Create(object, tweenInfo, propertyTable)

    if not tweens[object] then
        tweens[object] = {}
    end

    for property in propertyTable do
        if property:find("Color3") then
            table.insert(colorTweens, tween)
            break
        end
    end

    Tweener.Stop(object, id)
    tweens[object][id] = tween

    if autoPlay then
        tween:Play()
    end

    return tween
end

function Tweener.Stop(object, id)
    local currentTween = tweens[object][id]
    if currentTween then
        currentTween:Cancel()
    end
end

function Tweener.StopColorTweens()
    for _, tween in colorTweens do
        tween:Cancel()
    end
end

function Tweener.TweenInfo(duration, easingStyle, easingDirection, ...): TweenInfo
    return TweenInfo.new(duration, easingStyle or DEFAULT_EASING_STYLE, easingDirection or DEFAULT_EASING_DIRECTION, ...)
end

return Tweener