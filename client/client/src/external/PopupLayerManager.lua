--弹窗管理器
local PopupLayerManager = class("PopupLayerManager")

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local kMaskLayerName = "popup_layer_mask"

function PopupLayerManager:ctor(scene)
    
    self._scene = scene
    self._mask = nil
    self._layers = {}
    --self._layerOrderMask = 10000000
    --self._layerOrder = self._layerOrderMask
end

function PopupLayerManager:show(layer, isMask, isHideFront)

    --是否有遮罩
    if isMask == nil then 
        isMask = true
    end
    --是否隐藏前窗
    if isHideFront == nil then
        isHideFront = true
    end

    --前面的弹窗全部隐藏
    if isHideFront then
        for i = 1, #self._layers do
            if self._layers[i]:getName() ~= kMaskLayerName then
                self._layers[i]:setVisible(false)
            end
        end
    end

    --创建遮罩
    if isMask then
        local mask = ccui.Layout:create()
        mask:setName(kMaskLayerName)
        mask:setContentSize(cc.Director:getInstance():getVisibleSize())
        mask:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        mask:setBackGroundColor(cc.BLACK)
        mask:setBackGroundColorOpacity(153)
        mask:setTouchEnabled(true)
        --mask:addTo(self._scene, self._layerOrder)
        mask:addTo(self._scene)
--        mask:addTouchEventListener(function(ref, type)

--            if type == ccui.TouchEventType.ended then

--                if #self._layers > 1 then
--                    local frontLayer = self._layers[#self._layers]
--                    if frontLayer.onTouchMask then
--                        frontLayer:onTouchMask()
--                    end
--                end
--            end
--        end)

        mask:setOpacity(0)
        mask:runAction(cc.EaseSineOut:create(cc.FadeIn:create(0.4)))

        --保存
        --self._layerOrder = self._layerOrder + 1
        table.insert(self._layers, #self._layers + 1, mask)
    end

    --添加到场景
    --layer:setPopupLayerManager(self)
    --layer:addTo(self._scene, self._layerOrder)
    layer:addTo(self._scene)

    if layer.onShow then 
        layer:onShow()
    end

    --保存
    --self._layerOrder = self._layerOrder + 1
    table.insert(self._layers, #self._layers + 1, layer)
end

function PopupLayerManager:dismiss(layer)
    
    --移除
    layer:removeFromParent()
    table.removebyvalue(self._layers, layer, true)

    --移除遮罩
    if #self._layers > 0 then
        local lastLayer = self._layers[#self._layers]

        if lastLayer:getName() == kMaskLayerName then
            self:dismiss(lastLayer)
        else
            --显示最后一个弹窗
            lastLayer = self._layers[#self._layers]
            lastLayer:setVisible(true)

            if lastLayer.onShow then 
                lastLayer:onShow()
            end
        end
    end
end

--获取弹出遮罩数量
function PopupLayerManager:getPopupMaskCount()
    
    local maskCount = 0

    for i = 1, #self._layers do
        
        if self._layers[i]:getName() == kMaskLayerName then
            maskCount = maskCount + 1
        end
    end

    return maskCount
end

--显示弹出窗口
function showPopupLayer(layer, isMask, isHideFront)
    
    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene == nil then
        return
    end

    if runningScene._popupLayerManager == nil then
        runningScene._popupLayerManager = PopupLayerManager:create(runningScene)
    end

    runningScene._popupLayerManager:show(layer, isMask, isHideFront)
end

--关闭弹出窗口
function dismissPopupLayer(layer)

    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene == nil then
        return
    end

    if runningScene._popupLayerManager == nil then
        return
    end

    runningScene._popupLayerManager:dismiss(layer)
end

--获取弹出遮罩数量
function getPopupMaskCount()

    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene == nil then
        return 0
    end

    if runningScene._popupLayerManager == nil then
        return 0
    end

    return runningScene._popupLayerManager:getPopupMaskCount()
end

return PopupLayerManager