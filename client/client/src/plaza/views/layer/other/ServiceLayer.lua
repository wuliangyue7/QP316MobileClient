--服务条款界面

local ServiceLayer = class("ServiceLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

function ServiceLayer:ctor(delegate)

    self._delegate = delegate

    local csbNode = ExternalFun.loadCSB("Service/ServiceLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    self._scrollView = self._content:getChildByName("scrollview")

    local str = cc.FileUtils:getInstance():getStringFromFile("Service/Service.txt")
	self._strLabel = cc.Label:createWithTTF(str, "fonts/round_body.ttf", 25)
							 :setAnchorPoint(cc.p(0.5, 0))
						     :setLineBreakWithoutSpace(true)
						     :setMaxLineWidth(890)
							 :setAlignment(cc.TEXT_ALIGNMENT_LEFT)
							 :setTextColor(cc.WHITE)
						     :addTo(self._scrollView)
	self._strLabel:setPosition(cc.p(890/2, 0))
	self._scrollView:setInnerContainerSize(cc.size(890, self._strLabel:getContentSize().height))

    --取消
    local btnCancel = self._content:getChildByName("btn_cancel")
    btnCancel:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --同意
    local btnConfirm = self._content:getChildByName("btn_confirm")
    btnConfirm:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        if self._delegate and self._delegate.onConfirmAgreement then
            self._delegate:onConfirmAgreement()
        end

        dismissPopupLayer(self)
    end)
end

function ServiceLayer:onShow()
    
    local px, py = self._content:getPosition()

    self._content:setPosition(px, py + appdf.HEIGHT / 2)

    --动画跳入
    self._content:runAction(cc.EaseBackOut:create(cc.MoveTo:create(0.4, cc.p(px, py))))
end

return ServiceLayer