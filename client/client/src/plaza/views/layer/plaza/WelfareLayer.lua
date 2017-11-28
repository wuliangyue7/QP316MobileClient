-- 福利
local WelfareLayer = class("WelfareLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local ActivityIndicator = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.general.ActivityIndicator")

local CheckinFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.CheckinFrame")
local RequestManager = appdf.req(appdf.CLIENT_SRC.."plaza.models.RequestManager")

local LogonRewardLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.LogonRewardLayer")
local ShopLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ShopLayer")
local TargetShareLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.TargetShareLayer")

local ListItemType =
{
    LogonReward = 1,
    BaseEnsure = 2,
    FirstRecharge = 3,
    Share = 4
}

function WelfareLayer:ctor()

    --初始化变量
    self._itemInfos = {
        {
            icon = "Welfare/icon_logonreward.png",
            title = "每日登录奖励",
            enabled = false,
            button = {
                "Welfare/btn_goto_0.png", "Welfare/btn_goto_1.png", "Welfare/btn_received.png"
            }
        },
        {
            icon = "Welfare/icon_golds.png",
            title = "救济金",
            enabled = false,
            button = {
                "Welfare/btn_receive_0.png", "Welfare/btn_receive_1.png", "Welfare/btn_received.png"
            }
        },
        {
            icon = "Welfare/icon_beans.png",
            title = "每日首充",
            enabled = true,
            button = {
                "Welfare/btn_recharge_0.png", "Welfare/btn_recharge_1.png", "Welfare/btn_recharge_0.png"
            }
        },
        {
            icon = "Welfare/icon_share.png",
            title = "分享有礼",
            enabled = true,
            button = {
                "Welfare/btn_share_0.png", "Welfare/btn_share_1.png", "Welfare/btn_share_0.png"
            }
        }
    }

    self._condition = 0         --救济金领取条件
    self._amount = 0            --救济金领取金额
    self._times = 0             --救济金领取次数

    self._listItems = {}

    --节点事件
    ExternalFun.registerNodeEvent(self)

	--网络处理
	self._checkinFrame = CheckinFrame:create(self, function(result, message)
        return self:onCheckInCallBack(result, message)
    end)

    local csbNode = ExternalFun.loadCSB("Welfare/WelfareLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    -- 关闭
    self._content:getChildByName("btn_close"):addClickEventListener( function()

        -- 播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end )

    --列表
    self._listView = self._content:getChildByName("listview")
    self._listView:setScrollBarEnabled(false)
    self:loadListView()

    --活动指示器
    self._activity = ActivityIndicator:create()
    self._activity:setPosition(self._content:getContentSize().width / 2, self._content:getContentSize().height / 2)
    self._activity:addTo(self._content)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content)

    --获取参数
    self._checkinFrame:onCheckinQuery()
end

function WelfareLayer:onShow()
    
    local bOldEnabled = self._itemInfos[ListItemType.LogonReward].enabled
    local bNewEnabled = not GlobalUserItem.bTodayChecked

    if bNewEnabled ~= bOldEnabled then
        --更新列表
        self._itemInfos[ListItemType.LogonReward].enabled = bNewEnabled
        self:updateListItem(ListItemType.LogonReward)
    end
end

function WelfareLayer:onExit()

    if self._checkinFrame:isSocketServer() then
        self._checkinFrame:onCloseSocket()
    end
end

--加载列表
function WelfareLayer:loadListView()

    for i = 1, #self._itemInfos do
        
        local itemInfo = self._itemInfos[i]
        local listItem = ccui.ImageView:create("Welfare/sp_item_bg.png")
        
        --图标
        local icon = cc.Sprite:create(itemInfo.icon)
                        :setPosition(80, 60)
                        :addTo(listItem)

        --标题
        local title = ccui.Text:create(itemInfo.title, "fonts/round_body.ttf", 26)
                        :setAnchorPoint(cc.p(0, 0.5))
                        :setPosition(141, 94)
                        :setColor(cc.c3b(196, 83, 7))
                        :addTo(listItem)

        --描述
        local description = ccui.Text:create(self:getListItemDescription(i), "fonts/round_body.ttf", 24)
                                :setName("description")
                                :setAnchorPoint(cc.p(0, 0.5))
                                :setPosition(141, 40)
                                :setColor(cc.c3b(217, 154, 97))
                                :addTo(listItem)

        --按钮
        local button = ccui.Button:create(itemInfo.button[1], itemInfo.button[2], itemInfo.button[3])
                            :setName("button")
                            :setPosition(900, 60)
                            :setEnabled(itemInfo.enabled)
                            :addTo(listItem)
                            :addClickEventListener(function()
                                self:onClickListItem(i)
                            end)
                        
        self._listView:pushBackCustomItem(listItem)
        self._listItems[i] = listItem
    end
end

--更新列表项
function WelfareLayer:updateListItem(index)

    local itemInfo =self._itemInfos[index]
    local listItem = self._listItems[index]
    local description = listItem:getChildByName("description")
    local button = listItem:getChildByName("button")

    description:setString(self:getListItemDescription(index))
    button:setEnabled(itemInfo.enabled)
end

--获取列表项描述
function WelfareLayer:getListItemDescription(index)

    local descriptions = {
        "每天送您一次人品大爆炸的机会！",
        "游戏币数量低于" .. self._condition .. "，每次可以领取" .. self._amount .. "（限" .. self._times .. "次/天）",
        "每日首充将赠送额外奖励，就那么任性！",
        "每天首次分享微信朋友圈，即可获得" .. GlobalUserItem.nShareSend .. "游戏币！"
    }

    if index < 1 or index > #descriptions then
        return ""
    end

    return descriptions[index]
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击列表项
function WelfareLayer:onClickListItem(index)

    --播放音效
    ExternalFun.playClickEffect()

    if index == ListItemType.LogonReward then       --登录奖励
        
        --已签到
        if GlobalUserItem.bTodayChecked then
            showToast(nil, "今日已领取登录奖励", 2.0)
            return
        end

        if GlobalUserItem.bLotteryConfiged then
            
            --显示领奖页面
            showPopupLayer(LogonRewardLayer:create(), false, true)
        else

            --转盘还没配置，获取转盘数据
            showPopWait()

            RequestManager.requestLotteryConfig(function(result, message)
                
                dismissPopWait()

                if result == 0 then
                    --显示领奖页面
                    showPopupLayer(LogonRewardLayer:create(), false, true)
                end
            end)
        end

    elseif index == ListItemType.BaseEnsure then    --救济金

        showPopWait()

        --领取救济金
        self._checkinFrame:onBaseEnsureTake()

    elseif index == ListItemType.FirstRecharge then --每日首充

        local parent = self:getParent()

        dismissPopupLayer(self)

        ShopLayer:create():addTo(parent)

    elseif index == ListItemType.Share then         --每日分享

        local function sharecall( isok )
			if type(isok) == "string" and isok == "true" then
				showToast(nil, "分享成功", 2)
				--获取奖励
				local ostime = os.time()
				local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
				local param = "action=GetMobileShare&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime) .. "&machineid=" .. GlobalUserItem.szMachine
				appdf.onHttpJsionTable(url ,"GET", param, function(jstable,jsdata)

                    GlobalUserItem.setTodayShare()
                        
                    if type(jstable) == "table" then
                        local data = jstable["data"]
                        local msg = jstable["msg"]
                        if type(data) == "table" and type(msg) == "string" and "" ~= msg then
                            GlobalUserItem.lUserScore = data["Score"] or GlobalUserItem.lUserScore
                            --通知更新        
                            local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
                            eventListener.obj = yl.RY_MSG_USERWEALTH
                            cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)

                            if type(msg) == "string" and "" ~= msg then
                                showToast(nil, msg, 2)
                            end                         
                        end
                    end
						
				end)
			end
		end
        local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
        MultiPlatform:getInstance():customShare(sharecall, nil, nil, url, "")

    end
end

--------------------------------------------------------------------------------------------------------------------
-- CheckInFrame 回调

function WelfareLayer:onCheckInCallBack(result, message)

    dismissPopWait()

    if type(message) == "string" and message ~= "" then
		showToast(nil,message,2)
	end

    --签到信息
    if result == 1 then
        
        self._itemInfos[ListItemType.LogonReward].enabled = not GlobalUserItem.bTodayChecked

        --更新列表
        self:updateListItem(ListItemType.LogonReward)

        --获取救济金信息
        self._checkinFrame:sendBaseEnsureLoad()

        return true

    --救济金信息
    elseif result == self._checkinFrame.BASEENSUREQUERY then

        self._condition = message.condition
        self._amount = message.amount
        self._times = message.times
        self._itemInfos[ListItemType.BaseEnsure].enabled = true

        --更新列表
        self:updateListItem(ListItemType.BaseEnsure)

        self._activity:stop()

    --领取救济金成功
    elseif result == 2 then
        
    end

    return false
end

return WelfareLayer