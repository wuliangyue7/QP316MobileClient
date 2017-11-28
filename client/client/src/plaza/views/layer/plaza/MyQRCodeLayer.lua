--我的二维码页面
local MyQRCodeLayer = class("MyQRCodeLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

function MyQRCodeLayer:ctor(info)

    local csbNode = ExternalFun.loadCSB("Spreader/MyQRCodeLayer.csb"):addTo(self)
    self._panelMask = csbNode:getChildByName("panel_mask")
    self._content = csbNode:getChildByName("content")

    --遮罩
    self._panelMask:addTouchEventListener(function(ref, type)
        
        if type == ccui.TouchEventType.ended then
            dismissPopupLayer(self)
        end
    end)

    --分享
    local btnShare = self._content:getChildByName("btn_share")
    btnShare:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        ExternalFun.popupTouchFilter(0, false)
        captureScreenWithArea(self._qrCodeFrame, "qr_code.png", function(ok, savepath)
			ExternalFun.dismissTouchFilter()
			if ok then
				MultiPlatform:getInstance():customShare(function(isok)
		         			end, "我的推广码", "分享我的推广码", self._qrContent, savepath, "true")
			end
		end)
    end)

    --保存
    local btnSave = self._content:getChildByName("btn_save")
    btnSave:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        ExternalFun.popupTouchFilter(0, false)
        captureScreenWithArea(self._qrCodeFrame, "qr_code.png", function(ok, savepath)	
            ExternalFun.dismissTouchFilter()		
			if ok then	
				if true == MultiPlatform:getInstance():saveImgToSystemGallery(savepath, "qr_code.png") then
					showToast(nil, "您的推广码二维码图片已保存至系统相册", 2)
				end
			end
		end)
    end)

    local contentSize = self._content:getContentSize()

    --二维码
    self._qrContent = GlobalUserItem.szSpreaderURL or yl.HTTP_URL
	self._qrCode = QrNode:createQrNode(self._qrContent, 500, 5, 1)
    self._qrCode:setPosition(contentSize.width / 2, contentSize.height / 2 + 40)
    self._qrCode:addTo(self._content)

    --logo
    local logo = cc.Sprite:create("Spreader/logo.png")
    logo:setPosition(self._qrCode:getPosition())
    logo:addTo(self._content)

    --保存二维码区域
    local frameSize = cc.Director:getInstance():getOpenGLView():getFrameSize()
    local areaSize = self._qrCode:getContentSize()
    local scaleX = frameSize.width / appdf.WIDTH
    local scaleY = frameSize.height / appdf.HEIGHT
    local worldPt = self._qrCode:convertToWorldSpace(self._qrCode:getAnchorPointInPoints());  
    self._qrCodeFrame = cc.rect((worldPt.x - areaSize.width / 2) * scaleX, (worldPt.y - areaSize.height / 2) * scaleY, areaSize.width * scaleX, areaSize.height * scaleY)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content)
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理


return MyQRCodeLayer