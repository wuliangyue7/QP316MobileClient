--[[
	等候界面
		2016_04_27 C.P
	功能：阻断用户输入，防止不必要的情况
]]
local PopWait = class("PopWait", function(isTransparent)
	if isTransparent then
		return display.newLayer(cc.c4b(0, 0, 0, 0))
	else
	 	return display.newLayer(cc.c4b(0, 0, 0, 153))
	end    
end)

--全局变量
g_popWait = nil

function PopWait:getInstance(isTransparent)
    
    if nil == g_popWait then
        g_popWait = PopWait:create(isTransparent)
    end

    return g_popWait
end

function PopWait:ctor(isTransparent)
	
	if width == nil or height == nil then
		self:setContentSize(display.width,display.height)
	else
		self:setContentSize(width,height)
	end
	
	local function onTouch(eventType, x, y)
        return true
    end
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(onTouch)

	--if not isTransparent then
		cc.Sprite:create("wait_round.png")
			:addTo(self)
			:move(appdf.WIDTH/2,appdf.HEIGHT/2 )	
			:runAction(cc.RepeatForever:create(cc.RotateBy:create(2 , -360)))
	--end	
end

--显示
function PopWait:show(parent)

    if self:getParent() then
        return self
    end

    if nil == parent then
        local runningScene = cc.Director:getInstance():getRunningScene()
        if runningScene then
            self:addTo(runningScene)
        end
    else
	    self:addTo(parent)
    end

	return self
end

--显示状态
function PopWait:isShow()
	return not self._dismiss 
end

--取消显示
function PopWait:dismiss()
	if self._dismiss then
		return
	end
	self._dismiss  = true
	self:runAction(cc.RemoveSelf:create())

    if g_popWait == self then
        g_popWait = nil
    end
end

--显示等候
function showPopWait(isTransparent)
    
    --默认无遮罩
    if isTransparent == nil then 
        isTransparent = true
    end

    PopWait:getInstance(isTransparent):show()
end

--取消等待
function dismissPopWait()
    
    if g_popWait ~= nil then
        g_popWait:dismiss()
    end
end

return PopWait