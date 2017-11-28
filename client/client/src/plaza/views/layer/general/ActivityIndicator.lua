--活动指示器
local ActivityIndicator = class("ActivityIndicator", cc.Sprite)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function ActivityIndicator:ctor(fileName, anglePerFrame, fps)

    if not fileName then
        fileName = "General/activity.png"
    end

    if not anglePerFrame then
        anglePerFrame = 45
    end

    if not fps then
        fps = 10
    end

    self._anglePerFrame = anglePerFrame
    self._fps = fps

    --注册节点事件
    ExternalFun.registerNodeEvent(self)

    --加载图片
    self:setTexture(fileName)

    --开始
    self:start()
end

function ActivityIndicator:onExit()
    
    self:stop()
end

--开始
function ActivityIndicator:start()

    self:setVisible(true)

    --停止动画
    self:stopAllActions()

    --旋转动画
    schedule(self, function()

        self:setRotation( (self:getRotation() + self._anglePerFrame) % 360 )
    end, 1.0 / self._fps)
end

--停止
function ActivityIndicator:stop()
    
    self:setVisible(false)

    --停止动画
    self:stopAllActions()
end

return ActivityIndicator