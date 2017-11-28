--推广页面
local SpreadingLayer = class("SpreadingLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local MyQRCodeLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.MyQRCodeLayer")

function SpreadingLayer:ctor(info)

    local csbNode = ExternalFun.loadCSB("Spreader/SpreadingLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --分享按钮
    local platforms = { yl.ThirdParty.WECHAT, yl.ThirdParty.WECHAT_CIRCLE, yl.ThirdParty.SMS }
    local btnNames = { "btn_weixin", "btn_circle", "btn_contact" }

    for i = 1, #btnNames do

        local btn = self._content:getChildByName(btnNames[i])
        btn:addClickEventListener(function()
            self:onClickShare(platforms[i])
        end)
    end

    --领取
    local btnReceive = self._content:getChildByName("btn_receive")
    btnReceive:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        local ostime = os.time()
        local url = appdf.HTTP_URL .. "/SyncLogin.aspx?userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime) .. "&url=/Member/SpreadBalance.aspx"

        cc.Application:getInstance():openURL(url)
    end)

    --复制
    local btnCopy = self._content:getChildByName("btn_copy")
    btnCopy:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        local url = GlobalUserItem.szSpreaderURL or yl.HTTP_URL
		local res, msg = MultiPlatform:getInstance():copyToClipboard(url)
		if true == res then
			showToast(nil, "复制到剪贴板成功!", 2)
		else
			if type(msg) == "string" then
				showToast(nil, msg, 2)
			end
		end
    end)

    --二维码
    local btnQrCode = self._content:getChildByName("btn_qrcode")
    btnQrCode:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        showPopupLayer(MyQRCodeLayer:create(), false, false)
    end)

    local qrContent = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
	local qrCode = QrNode:createQrNode(qrContent, 200, 5, 1)
    qrCode:setPosition(btnQrCode:getPosition())
    qrCode:addTo(self._content)

    --分享奖励
    local txtRewardTip = self._content:getChildByName("txt_reward_tip")
    txtRewardTip:setString("推广成功即可获得" .. GlobalUserItem.nInviteSend .. "奖励！")

    -- 内容跳入
    AnimationHelper.jumpIn(self._content)
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击分享
function SpreadingLayer:onClickShare(platform)
    
    --播放音效
    ExternalFun.playClickEffect()

	local function sharecall( isok )
        if type(isok) == "string" and isok == "true" then
            showToast(nil, "分享完成", 2)
        end
    end

    local url = GlobalUserItem.szSpreaderURL or yl.HTTP_URL

    if platform == yl.ThirdParty.WECHAT or platform == yl.ThirdParty.WECHAT_CIRCLE then
        MultiPlatform:getInstance():shareToTarget(platform, sharecall, yl.SocialShare.title, yl.SocialShare.content, url)
    elseif platform == yl.ThirdParty.SMS then
        local msg = "亲爱的好友，我最近玩了一款超好玩的游戏，玩法超级多，内容超级精彩，快来加入我，和我一起精彩游戏吧！下载地址：" .. url
        MultiPlatform:getInstance():shareToTarget(platform, sharecall, yl.SocialShare.title, msg)
    end
    
end

return SpreadingLayer