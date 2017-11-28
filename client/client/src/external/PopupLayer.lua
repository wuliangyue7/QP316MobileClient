--弹窗
local PopupLayer = class("PopupLayer", cc.Layer)

function PopupLayer:getPopupLayerManager()

    return self._popupLayerManager
end

function PopupLayer:setPopupLayerManager(manager)

    self._popupLayerManager = manager
end

--是否隐藏前面的窗口
function PopupLayer:isHideFrontLayer()

    return self._hideFront or true
end

--设置是否隐藏前面的窗口
function PopupLayer:setHideFrontLayer(hideFront)
    
    self._hideFront = hideFront
end

--弹窗消失
function PopupLayer:dismiss()
    
    if self._popupLayerManager then
        self._popupLayerManager:pop(self)
    else
        self:removeFromParent()
    end
end

return PopupLayer