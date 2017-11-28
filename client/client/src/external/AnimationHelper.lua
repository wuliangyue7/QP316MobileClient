-- 动画帮助类
local AnimationHelper = class("AnimationHelper")

-- 默认动画时间
local DEFAULT_DURATION = 0.4

-- 获取默认动画时间
function AnimationHelper.defaultDuration()

    return DEFAULT_DURATION
end

-- 动画跳入
function AnimationHelper.jumpInEx( target, duration, finishCallback )

    if not target then
        return
    end 

    target:setScale(0)

    local sequence = cc.Sequence:create(
                                --cc.EaseSineIn:create(cc.ScaleTo:create(duration * 0.5, 1.1)), 
                                --cc.EaseSineIn:create(cc.ScaleTo:create(duration * 0.25, 0.95)),
                                --cc.EaseSineIn:create(cc.ScaleTo:create(duration * 0.25, 1.0)),
                                cc.EaseBackOut:create(cc.ScaleTo:create(duration, 1.0)),
                                cc.CallFunc:create(function()
                                    if finishCallback then 
                                        finishCallback() 
                                    end
                                end)
                                )

    target:runAction(sequence)
end

-- 动画跳入
function AnimationHelper.jumpIn( target, finishCallback )

    AnimationHelper.jumpInEx(target, DEFAULT_DURATION, finishCallback)
end

-- 动画跳出
function AnimationHelper.jumpOutEx( target, duration, finishCallback )

    if not target then
        return
    end 

    local sequence = cc.Sequence:create(
                                cc.EaseSineOut:create(cc.ScaleTo:create(duration * 0.25, 0.95)), 
                                cc.EaseSineOut:create(cc.ScaleTo:create(duration * 0.25, 1.1)),
                                cc.EaseSineOut:create(cc.ScaleTo:create(duration * 0.5, 0)),
                                cc.CallFunc:create(function()
                                    if finishCallback then 
                                        finishCallback() 
                                    end
                                end)
                                )

    target:runAction(sequence)
end

-- 动画跳出
function AnimationHelper.jumpOut( target, finishCallback )
    
    AnimationHelper.jumpOutEx(target, DEFAULT_DURATION, finishCallback)
end

-- 动画跳入到
function AnimationHelper.jumpInTo( target, duration, ptTo, shakeX, shakeY, finishCallback )

    if not target then
        return
    end 

    local sequence = cc.Sequence:create(
                                cc.EaseSineIn:create(cc.MoveTo:create(duration * 0.5, cc.p(ptTo.x + shakeX, ptTo.y + shakeY))), 
                                cc.EaseSineIn:create(cc.MoveTo:create(duration * 0.25, cc.p(ptTo.x - shakeX / 1, ptTo.y - shakeY / 1))),
                                cc.EaseSineIn:create(cc.MoveTo:create(duration * 0.25, ptTo)),
                                cc.CallFunc:create(function()
                                    if finishCallback then 
                                        finishCallback() 
                                    end
                                end)
                                )

    target:runAction(sequence)
end

-- 动画跳出到
function AnimationHelper.jumpOutTo( target, duration, ptTo, shakeX, shakeY, finishCallback )

    if not target then
        return
    end 

    --初始位置
    local ptFrom = cc.p(target:getPosition())

    local sequence = cc.Sequence:create(
                                cc.EaseSineOut:create(cc.MoveTo:create(duration * 0.25, cc.p(ptFrom.x - shakeX / 1, ptFrom.y - shakeY / 1))),
                                cc.EaseSineOut:create(cc.MoveTo:create(duration * 0.25, cc.p(ptFrom.x + shakeX, ptFrom.y + shakeY))),
                                cc.EaseSineOut:create(cc.MoveTo:create(duration * 0.5, ptTo)), 
                                cc.CallFunc:create(function()
                                    if finishCallback then 
                                        finishCallback() 
                                    end
                                end)
                                )

    target:runAction(sequence)
end

-- 动画移出到
function AnimationHelper.moveOutTo( target, duration, ptTo, finishCallback )
    
    if not target then
        return
    end 

    local sequence = cc.Sequence:create(
                                cc.EaseSineOut:create(cc.MoveTo:create(duration, ptTo)), 
                                cc.CallFunc:create(function()
                                    if finishCallback then 
                                        finishCallback() 
                                    end
                                end)
                                )

    target:runAction(sequence)
end

-- 渐变入到
function  AnimationHelper.alphaInTo( target, duration, opacity, finishCallback )

    if not target then
        return
    end 

    local sequence = cc.Sequence:create(
                                cc.EaseSineIn:create(cc.FadeTo:create(duration, opacity)), 
                                cc.CallFunc:create(function()
                                    if finishCallback then 
                                        finishCallback() 
                                    end
                                end)
                                )

    target:runAction(sequence)
end

-- 渐变出到
function  AnimationHelper.alphaOutTo( target, duration, opacity, finishCallback )

    if not target then
        return
    end 

    local sequence = cc.Sequence:create(
                                cc.EaseSineOut:create(cc.FadeTo:create(duration, opacity)), 
                                cc.CallFunc:create(function()
                                    if finishCallback then 
                                        finishCallback() 
                                    end
                                end)
                                )

    target:runAction(sequence)
end

return AnimationHelper