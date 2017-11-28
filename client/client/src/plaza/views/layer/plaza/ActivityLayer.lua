--游戏活动
local ActivityLayer = class("ActivityLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local ActivityIndicator = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.general.ActivityIndicator")

local ZORDER = 
{
    WEBVIEW = 10,
    ACTIVITY = 10000,
}

function ActivityLayer:ctor()

    local csbNode = ExternalFun.loadCSB("Activity/ActivityLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --活动指示器
    self._activity = ActivityIndicator:create()
    self._activity:setPosition(self._content:getContentSize().width / 2, self._content:getContentSize().height / 2)
    self._activity:addTo(self._content, ZORDER.ACTIVITY)

    --平台判定
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then

        local url = yl.HTTP_URL .. "/SyncLogin.aspx?userid="..GlobalUserItem.dwUserID.."&time="..os.time().."&signature="..GlobalUserItem:getSignature(os.time()).."&url=/Mobile/AdsNotice.aspx"

        --网页
        self._webView = ccexp.WebView:create()
        self._webView:setPosition(self._content:getContentSize().width / 2, self._content:getContentSize().height / 2 - 30)
        self._webView:setContentSize(937, 485)
        self._webView:setScalesPageToFit(true) 
        self._webView:loadURL(url)
        self._webView:addTo(self._content, ZORDER.WEBVIEW)
        
        self._webView:setOnShouldStartLoading(function(sender, url)
            
            --print("WebView_onShouldStartLoading, url is ", url)
            self._activity:start()

            --隐藏网页
            --ExternalFun.visibleWebView(self._webView, false)
                   
            return true
        end)
        self._webView:setOnDidFailLoading(function ( sender, url )

            print("WebView_onDidFailLoading, url is ", url) 
            self._activity:stop()

            return true
        end)
        self._webView:setOnDidFinishLoading(function(sender, url)

            print("WebView_onDidFinishLoading, url is ", url)
            self._activity:stop()

            --显示网页
            --ExternalFun.visibleWebView(self._webView, true)

            return true
        end)

        --网页初始化不显示
        --ExternalFun.visibleWebView(self._webView, false)
    else
        
        local layout = ccui.Layout:create()
        layout:setAnchorPoint(cc.p(0.5,0.5))
        layout:setBackGroundColor(cc.RED)
        layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        layout:setBackGroundColorOpacity(100)
        layout:setContentSize(cc.size(937, 485))
        layout:setPosition(self._content:getContentSize().width / 2, self._content:getContentSize().height / 2 - 30)
        layout:addTo(self._content)
    end

    --内容跳出
    AnimationHelper.jumpIn(self._content)
end

return ActivityLayer