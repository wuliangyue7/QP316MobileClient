--验证窗口
local ValidateLayer = class("ValidateLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function ValidateLayer:ctor()

    local csbNode = ExternalFun.loadCSB("Validate/ValidateLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --平台判定
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then

        local url = "http://validate2.w45.com:85/validate.html"

        --网页
        self._webView = ccexp.WebView:create()
        self._webView:setPosition(self._content:getContentSize().width / 2, self._content:getContentSize().height / 2 - 30)
        self._webView:setContentSize(750, 380)
        self._webView:setScalesPageToFit(true) 
        self._webView:loadURL(url)
        self._webView:addTo(self._content)
        
        self._webView:setOnShouldStartLoading(function(sender, url)
            
            --print("WebView_onShouldStartLoading, url is ", url)

            
            return true
        end)
        self._webView:setOnDidFailLoading(function ( sender, url )

            print("WebView_onDidFailLoading, url is ", url) 

            return true
        end)
        self._webView:setOnDidFinishLoading(function(sender, url)

            print("WebView_onDidFinishLoading, url is ", url)

            --验证成功，关闭
            if url == "http://validate2.w45.com:85/success.html" then
                
                dismissPopupLayer(self)
            end

            return true
        end)

    else
        
        local layout = ccui.Layout:create()
        layout:setAnchorPoint(cc.p(0.5,0.5))
        layout:setBackGroundColor(cc.RED)
        layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        layout:setBackGroundColorOpacity(100)
        layout:setContentSize(cc.size(750, 380))
        layout:setPosition(self._content:getContentSize().width / 2, self._content:getContentSize().height / 2 - 30)
        layout:addTo(self._content)
    end

    --内容跳出
    --AnimationHelper.jumpIn(self._content)
end

return ValidateLayer