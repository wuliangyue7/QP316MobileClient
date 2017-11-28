--[[
  登录界面
      2015_12_03 C.P
      功能：登录/注册
--]]
local LogonScene = class("LogonScene", cc.load("mvc").ViewBase)

if not yl then
	appdf.req(appdf.CLIENT_SRC.."plaza.models.yl")
end
if not GlobalUserItem then
	appdf.req(appdf.CLIENT_SRC.."plaza.models.GlobalUserItem")
end

local PopWait = appdf.req(appdf.BASE_SRC.."app.views.layer.other.PopWait")
local QueryExit = appdf.req(appdf.BASE_SRC.."app.views.layer.other.QueryDialog")

local LogonFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.LogonFrame")
local LogonLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.logon.LogonLayer")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local PopupLayerManager = appdf.req(appdf.EXTERNAL_SRC .. "PopupLayerManager")

local RequestManager = appdf.req(appdf.CLIENT_SRC.."plaza.models.RequestManager")

local ValidateLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ValidateLayer")
local ValidateMobileLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ValidateMobileLayer")

local targetPlatform = cc.Application:getInstance():getTargetPlatform()

--全局处理lua错误
cc.exports.g_LuaErrorHandle = function ()
	cc.exports.bHandlePopErrorMsg = true
	if isDebug() then
		print("debug return")
		return true
	else
		print("release return")
		return false
	end
end

--加载配置
function LogonScene.onceExcute()
	local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
	--文件日志
	LogAsset:getInstance():init(MultiPlatform:getInstance():getExtralDocPath(), true, true)

	--配置微信
	MultiPlatform:getInstance():thirdPartyConfig(yl.ThirdParty.WECHAT, yl.WeChat)
	--配置支付宝
    if not yl.APPSTORE_VERSION then
	    MultiPlatform:getInstance():thirdPartyConfig(yl.ThirdParty.ALIPAY, yl.AliPay)
    end
	--配置竣付通
	--MultiPlatform:getInstance():thirdPartyConfig(yl.ThirdParty.JFT, yl.JFT)
	--配置分享
	MultiPlatform:getInstance():configSocial(yl.SocialShare)
	--配置高德
	--MultiPlatform:getInstance():thirdPartyConfig(yl.ThirdParty.AMAP, yl.AMAP)
end
LogonScene.onceExcute()

-- 初始化界面
function LogonScene:onCreate()

	print("LogonScene:onCreate()")

    --网络处理
    self._logonFrame = LogonFrame:create(self, function(result, message)
        self:onLogonCallBack(result, message)
    end)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    --背景
    cc.Sprite:create("base/res/background.jpg")
        :setPosition(appdf.WIDTH/2, appdf.HEIGHT/2)
        :addTo(self)

    --logo
    self._logo = cc.Sprite:create("base/res/logo.png")
        :setPosition(185, 670)
        :setOpacity(yl.APPSTORE_VERSION and 0 or 255)
        :addTo(self)

    --animal
    self._animal = cc.Sprite:create("base/res/animal.png")
        :setPosition(appdf.WIDTH / 2 + 45, appdf.HEIGHT / 2 + 15)
        :addTo(self)

    --提示文本
    local tip = "v " .. appdf.BASE_C_VERSION .. "." .. (self:getApp()._version:getResVersion() or appdf.BASE_C_RESVERSION)
	self._txtTips = cc.Label:createWithTTF(tip, "fonts/round_body.ttf", 24)
		:setTextColor(cc.WHITE)
		:setAnchorPoint(cc.p(1,0))
		:enableOutline(cc.c4b(0,0,0,255), 1)
		:move(appdf.WIDTH,0)
		:addTo(self)

    --微信登录
    self._btnLogonWx = ccui.Button:create("Logon/logon_wx_0.png", "Logon/logon_wx_1.png")
    self._btnLogonWx:setPosition(appdf.WIDTH / 2 - 380, 130)
    self._btnLogonWx:setVisible(true)
    self._btnLogonWx:addClickEventListener(function() self:onClickWx() end)
    self._btnLogonWx:addTo(self)

    --游客登录
    self._btnLogonVisitor = ccui.Button:create("Logon/logon_visitor_0.png", "Logon/logon_visitor_1.png")
    self._btnLogonVisitor:setPosition(appdf.WIDTH / 2, 130)
    self._btnLogonVisitor:setVisible(true)
    self._btnLogonVisitor:addClickEventListener(function() self:onClickVisitor() end)
    self._btnLogonVisitor:addTo(self)

    --账号登录
    self._btnLogonAccount = ccui.Button:create("Logon/logon_account_0.png", "Logon/logon_account_1.png")
    self._btnLogonAccount:setPosition(appdf.WIDTH / 2 + 380, 130)
    self._btnLogonAccount:setVisible(true)
    self._btnLogonAccount:addClickEventListener(function() self:onClickAccount() end)
    self._btnLogonAccount:addTo(self)

    --刷新按钮
    self:onRefreshLogonButtons()

	--读取配置
	GlobalUserItem.LoadData()

	--背景音乐
	ExternalFun.playPlazzBackgroudAudio()

    --微信第一次登录赠送奖励
--    if GlobalUserItem.thirdPartyData.accounts == nil or GlobalUserItem.thirdPartyData.accounts == "" then

--        if yl.SHOW_WECHAT_REWARD == nil then
--            yl.SHOW_WECHAT_REWARD = true
--            showToast(self, "微信首次登录即可获得30万游戏币哦，快来领取吧！", 10)
--        end
--    end

    local notice = self:getApp()._serverConfig["notice"]

    --公告
    if yl.SHOW_STARTUP_NOTICE == nil and type(notice) == "string" and notice ~= "" then
        yl.SHOW_STARTUP_NOTICE = true
        showToast(self, notice, 10)
    --手机绑定提示
    elseif yl.SHOW_MOBILE_BINDING_TIP == nil then
        yl.SHOW_MOBILE_BINDING_TIP = true
        showToast(self, "", 5)
    end
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--退出场景
function LogonScene:onExit()
    
    if self._logonFrame:isSocketServer() then
        self._logonFrame:onCloseSocket()
    end
end

--进入场景完成
function LogonScene:onEnterTransitionFinish()

--    self:runAction(
--        cc.CallFunc:create(function()

--            --显示安全验证
--            showPopupLayer(ValidateLayer:create())
--        end)
--    )

    self:runAction(
        cc.CallFunc:create(function()

            --请求服务器地址
            RequestManager.requestServerAddress()

        end)
    )

end

--刷新登录按钮
function LogonScene:onRefreshLogonButtons()

    local logonBtns = {}

    if MultiPlatform.getInstance():isPlatformInstalled(yl.ThirdParty.WECHAT) then --已安装微信，才显示微信登录
        table.insert(logonBtns, self._btnLogonWx)
    end
    --if not GlobalUserItem.getBindingAccount() then  --绑定过账号，就不显示游客登录了
        table.insert(logonBtns, self._btnLogonVisitor)
    --end
    table.insert(logonBtns, self._btnLogonAccount)

    local xStart = appdf.WIDTH / 2 + 190 * (1 - #logonBtns)
--    if #logonBtns == 1 then
--        xStart = appdf.WIDTH / 2
--    elseif #logonBtns == 2 then
--        xStart = appdf.WIDTH / 2 - 190
--    else
--        xStart = appdf.WIDTH / 2 - 380
--    end

    for i = 1, #logonBtns do
        logonBtns[i]:setVisible(true)
        logonBtns[i]:setPosition(xStart + (i - 1) * 380, 130)
    end

    --保存登录按钮
    self._logonButtons = logonBtns
end

--显示动画
function LogonScene:onShowAnimation()

    local nodes = { self._logo, self._animal }

    for i = 1, #nodes do

        local px, py = nodes[i]:getPosition()
        nodes[i]:setPosition(px, py + appdf.HEIGHT / 2)

        --动画跳入
        nodes[i]:runAction(cc.EaseBackOut:create(cc.MoveTo:create(0.4, cc.p(px, py))))
    end
end

--微信登录
function LogonScene:onClickWx()
    
    print("===========微信登录===========")

    --播放音效
    ExternalFun.playClickEffect()

    --平台判定
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then
		
        self._Operate = 3
        self._tThirdData = GlobalUserItem.thirdPartyData
        --dump(self._tThirdData)

	    showPopWait()

        --使用保存的数据登录
        if type(self._tThirdData.accounts) == "string" and self._tThirdData.accounts ~= "" then
            self._logonFrame:onLoginByThirdParty(self._tThirdData.accounts, self._tThirdData.nickname, self._tThirdData.gender, self._tThirdData.platform)
            return
        end

        local function loginCallBack ( param )

		    dismissPopWait()

		    if type(param) == "string" and string.len(param) > 0 then
			    local ok, datatable = pcall(function()
					    return cjson.decode(param)
			    end)
			    if ok and type(datatable) == "table" then
				    --dump(datatable, "微信数据", 5)
				
				    local accounts = datatable["unionid"] or ""
				    local nickname = datatable["screen_name"] or ""
				    local headurl = datatable["profile_image_url"] or ""
				    local gender = datatable["gender"] or "0"
				    gender = tonumber(gender)
				    
				    self._tThirdData = 
				    {
					    accounts = accounts,
					    nickname = nickname,
                        headurl = headurl,
					    gender = gender,
					    platform = yl.PLATFORM_LIST[yl.ThirdParty.WECHAT],
				    }

                    --dump(self._tThirdData)

                    showPopWait()

				    self._logonFrame:onLoginByThirdParty(accounts, nickname, gender, yl.PLATFORM_LIST[yl.ThirdParty.WECHAT])
			    end
		    end
	    end

        MultiPlatform:getInstance():thirdPartyLogin(yl.ThirdParty.WECHAT, loginCallBack)

        --防止用户取消微信登录一直转圈
        self:runAction(cc.Sequence:create(cc.DelayTime:create(5), cc.CallFunc:create(function()
			dismissPopWait()
		end)))
	else
		showToast(nil, "不支持的登录平台 ==> " .. targetPlatform, 2)
	end
end

--游客登录
function LogonScene:onClickVisitor()

    print("===========游客登录===========")

    --播放音效
    ExternalFun.playClickEffect()

	showPopWait()

	self._Operate = 2
	self._logonFrame:onLogonByVisitor()
end

--账号登录
function LogonScene:onClickAccount()

    print("===========账号登录===========")

    --播放音效
    ExternalFun.playClickEffect()

    --隐藏
    self._logo:setVisible(false)
    self._animal:setVisible(false)

    for i = 1, #self._logonButtons do
        self._logonButtons[i]:setVisible(false)
    end

    showPopupLayer(LogonLayer:create(self), false)
end

--------------------------------------------------------------------------------------------------------------------
-- LogonLayer 回调

--登录框关闭
function LogonScene:onLogonLayerClose()
    
    self._logo:setVisible(true)
    self._animal:setVisible(true)

    for i = 1, #self._logonButtons do
        self._logonButtons[i]:setVisible(true)
    end

    --显示动画
    --self:onShowAnimation()
end

--账号登录
function LogonScene:onLogonAccount(szAccount, szPassword, bSave, bAuto)

	--参数记录
	self._szAccount = szAccount
	self._szPassword = szPassword
	self._bAuto = bAuto
	self._bSave = bSave

    showPopWait()

    self._Operate = 0
	self._logonFrame:onLogonByAccount(szAccount, szPassword)
end

--------------------------------------------------------------------------------------------------------------------
-- RegisterLayer 回调

--账号注册
function LogonScene:onRegisterAccount(szAccount, szNickName, szPassword, szMobile, szSMSCode)

	--参数记录
	self._szAccount = szAccount
	self._szPassword = szPassword
	self._bAuto = false
	self._bSave = true
	self._gender = math.random(1)

	showPopWait()

	self._Operate = 1
	self._logonFrame:onRegister(szAccount, szNickName, szPassword, self._gender, szMobile, szSMSCode)
end

--------------------------------------------------------------------------------------------------------------------
-- ValidateMobileLayer 回调

--确认验证
function LogonScene:onConfirmMobileValidate(szSMSCode)

    --保存验证码
    self._logonFrame._szSMSCode = szSMSCode

    --重新登录
    if self._Operate == 0 then

        --账号登录
        self:onLogonAccount(self._szAccount, self._szPassword, self._bAuto, false) --出现手机验证后，不保存密码

    elseif self._Operate == 3 then

        --微信登录
        self:onClickWx()
    end
end

--------------------------------------------------------------------------------------------------------------------
-- LogonFrame 回调

function LogonScene:onLogonCallBack(result, message)
    
    if result ~= 1 then
        dismissPopWait()
    end

    --需要手机验证
    if result == 55 then
        showPopupLayer(ValidateMobileLayer:create(self, message), false)
        return
    end

    if type(message) == "string" and message ~= "" then
        showToast(nil, message, 2)
    end

    if result == 1 then --成功
		--本地保存
		if self._Operate == 2 then 					--游客登录
			GlobalUserItem.bAutoLogon = false
			GlobalUserItem.bSavePassword = false
			GlobalUserItem.szPassword = "WHYK@foxuc.cn"
			--GlobalUserItem.szAccount = GlobalUserItem.szNickName
		elseif self._Operate == 3 then 				--微信登陆
			GlobalUserItem.szThirdPartyUrl = self._tThirdData.headurl
			GlobalUserItem.szPassword = "WHYK@foxuc.cn"
			GlobalUserItem.bThirdPartyLogin = true
			GlobalUserItem.thirdPartyData = self._tThirdData
			--GlobalUserItem.szAccount = GlobalUserItem.szNickName

            --保存第三方登录数据，下次可以直接登录不用验证
            cc.UserDefault:getInstance():setStringForKey("thirdparty_accounts", self._tThirdData.accounts)
            cc.UserDefault:getInstance():setStringForKey("thirdparty_nickname", self._tThirdData.nickname)
            cc.UserDefault:getInstance():setStringForKey("thirdparty_headurl", self._tThirdData.headurl)
            cc.UserDefault:getInstance():setIntegerForKey("thirdparty_gender", self._tThirdData.gender)
            cc.UserDefault:getInstance():setIntegerForKey("thirdparty_platform", self._tThirdData.platform)

            dump(self._tThirdData)
		else
			GlobalUserItem.bAutoLogon = self._bAuto
			GlobalUserItem.bSavePassword = self._bSave
			GlobalUserItem.onSaveAccountConfig()
		end

		if yl.HTTP_SUPPORT then

			local ostime = os.time()
			appdf.onHttpJsionTable(yl.HTTP_URL .. "/WS/MobileInterface.ashx","GET","action=GetMobileShareConfig&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime),function(jstable,jsdata)

                dismissPopWait()

				local msg = nil
				if type(jstable) == "table" then
					local data = jstable["data"]
					msg = jstable["msg"]
					if type(data) == "table" then
						local valid = data["valid"]
						if valid then
							local count = data["FreeCount"] or 0
							GlobalUserItem.nTableFreeCount = tonumber(count)
							local sharesend = data["SharePresent"] or 0
							GlobalUserItem.nShareSend = tonumber(sharesend)
                            local onlineCount = data["Online"] or 0
                            GlobalUserItem.OnlineBaseCount = tonumber(onlineCount)

							--推广链接
							GlobalUserItem.szSpreaderURL = data["SpreaderUrl"]
							if nil == GlobalUserItem.szSpreaderURL or "" == GlobalUserItem.szSpreaderURL then
								GlobalUserItem.szSpreaderURL = yl.HTTP_URL ..  "/Mobile/Register.aspx"
							else
								GlobalUserItem.szSpreaderURL = string.gsub(GlobalUserItem.szSpreaderURL, " ", "")
							end
							-- 微信平台推广链接
							GlobalUserItem.szWXSpreaderURL = data["WxSpreaderUrl"]
							if nil == GlobalUserItem.szWXSpreaderURL or "" == GlobalUserItem.szWXSpreaderURL then
								GlobalUserItem.szWXSpreaderURL = yl.HTTP_URL ..  "/Mobile/Register.aspx"
							else
								GlobalUserItem.szWXSpreaderURL = string.gsub(GlobalUserItem.szWXSpreaderURL, " ", "")
							end

							-- 每日必做列表
							GlobalUserItem.tabDayTaskCache = {}
							local dayTask = data["DayTask"]
							if type(dayTask) == "table" then
								for k,v in pairs(dayTask) do
									if tonumber(v) == 0 then
										GlobalUserItem.tabDayTaskCache[k] = 1
										GlobalUserItem.bEnableEveryDay = true
									end
								end
							end
							GlobalUserItem.bEnableCheckIn = (GlobalUserItem.tabDayTaskCache["Field1"] ~= nil)
							GlobalUserItem.bEnableTask = (GlobalUserItem.tabDayTaskCache["Field6"] ~= nil)
							
							-- 邀请送金
							local sendcount = data["RegGold"]
							GlobalUserItem.nInviteSend = tonumber(sendcount) or 0

							--进入游戏列表
							self:getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.ClientScene","FADE",1)
							--FriendMgr:getInstance():reSetAndLogin()
							return
						end
					end
				end

				local str = "游戏登陆异常"
				if type(msg) == "string" then
					str = str .. ":" .. msg
				end
				showToast(nil, str, 3, cc.c3b(250,0,0))
			end)
		else
			--整理代理游戏列表
			if table.nums(self._logonFrame.m_angentServerList) > 0 then
				self:arrangeGameList(self._logonFrame.m_angentServerList)
			else
				self:getApp()._gameList = GlobalUserItem.m_tabOriginGameList
			end

			--进入游戏列表
			self:getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.ClientScene","FADE",1)
			--FriendMgr:getInstance():reSetAndLogin()
		end		
	end
end

return LogonScene