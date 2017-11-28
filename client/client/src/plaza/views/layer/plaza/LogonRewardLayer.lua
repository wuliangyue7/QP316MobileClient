--登录奖励
local LogonRewardLayer = class("LogonRewardLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local RewardShowLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.RewardShowLayer")

function LogonRewardLayer:ctor()

    --初始化数据
    self._drawReward = 0
    self._logonReward = 0
    self._totalReward = 0

    local csbNode = ExternalFun.loadCSB("LogonReward/LogonRewardLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    self._spTable = self._content:getChildByName("sp_table")
    self._spTableItemHighlight = self._content:getChildByName("sp_table_item_highlight")
    self._spTableItemFlash0 = self._content:getChildByName("sp_table_item_flash_0")
    self._spTableItemFlash1 = self._content:getChildByName("sp_table_item_flash_1")
    self._panelSign = self._content:getChildByName("panel_sign")
    self._panelResult = self._content:getChildByName("panel_result")

    --关闭
    self._btnClose = self._content:getChildByName("btn_close")
    self._btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --抽奖
    self._btnDraw = self._content:getChildByName("btn_draw")
    self._btnDraw:addClickEventListener(function()
        
        self:onClickDraw()
    end)

    --领取
    local btnReceive = self._panelResult:getChildByName("btn_receive")
    btnReceive:addClickEventListener(function()
        
        self:onClickReceive()
    end)

    --填充转盘信息
    local x0 = self._spTable:getContentSize().width / 2
    local y0 = self._spTable:getContentSize().height / 2
    for i = 1, #GlobalUserItem.dwLotteryQuotas do
        
        local txtQuota = ccui.Text:create(GlobalUserItem.dwLotteryQuotas[i], "fonts/round_body.ttf", 40)
        local x = x0   +   170   *   math.sin((i - 1) * 30   *   3.14   /180   ) 
        local y = y0   +   170   *   math.cos((i - 1) * 30   *   3.14   /180   ) 

        txtQuota:setPosition(x, y)
        txtQuota:setRotation( (270 + (i - 1) * 30) % 360 )
        txtQuota:enableOutline(cc.c3b(136, 70, 0), 1)
        txtQuota:addTo(self._spTable)
    end

    --更新签到信息
    self:onUpdateSignInfo()

    --内容跳入
    AnimationHelper.jumpIn(self._content)
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--更新签到信息
function LogonRewardLayer:onUpdateSignInfo()

    local txtSignDays = self._panelSign:getChildByName("txt_sign_days")
    txtSignDays:setString("已连续签到 " .. GlobalUserItem.wSeriesDate .. " 天")

    local wSeriesDate = GlobalUserItem.wSeriesDate
    local bTodayChecked = GlobalUserItem.bTodayChecked

    for i = 1, yl.LEN_WEEK do
        
        local spGoldItemBg = self._panelSign:getChildByName("sp_gold_item_bg_" .. i)
        local spGoldItem = spGoldItemBg:getChildByName("sp_gold_item")
        local spReceived = spGoldItemBg:getChildByName("sp_received")
        local txtReward = spGoldItemBg:getChildByName("txt_reward")

        local bSigned = wSeriesDate >= i                                    --已签到
        local bCanSign = (wSeriesDate + 1 == i and not bTodayChecked)       --可签到
        --local bToday = bTodayChecked and (wSeriesDate == i and true or false) or (wSeriesDate == i - 1 and true or false) --是否是今日
        
        --背景
        spGoldItemBg:setTexture("LogonReward/sp_gold_item_bg_" .. (bCanSign and 1 or 0) .. ".png")

        --金币
        spGoldItem:setTexture("LogonReward/sp_gold_item_" .. i .. "_" .. (bSigned and 1 or 0) .. ".png")

        --已签到标志
        spReceived:setVisible(bSigned)

        --奖励金额
        txtReward:setString(GlobalUserItem.lCheckinRewards[i])
    end
end

--更新奖励结果
function LogonRewardLayer:onUpdateRewardResult()
    
    local txtDrawReward = self._panelResult:getChildByName("txt_draw_reward")
    local txtLogonReward = self._panelResult:getChildByName("txt_logon_reward")
    local txtTotalReward = self._panelResult:getChildByName("txt_total_reward")

    txtDrawReward:setString(self._drawReward)
    txtLogonReward:setString(self._logonReward)
    txtTotalReward:setString(self._totalReward)
end

--转盘开始
function LogonRewardLayer:onTurnTableBegin(index)

    local itemCount = #GlobalUserItem.dwLotteryQuotas
    local degree = 1800 + (itemCount - index + 1) * (360 / itemCount)

    self._spTable:runAction(cc.Sequence:create( 
        cc.EaseSineInOut:create(cc.RotateTo:create(5.0, degree)),
        cc.CallFunc:create(function()
            
            self:onTurnTableEnd()
        end)
        )
    )

    --转盘音效
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.8),
        cc.CallFunc:create(function()
            ExternalFun.playPlazaEffect("zhuanpanBegin.mp3")
        end)
        )
    )
end

--转盘结束
function LogonRewardLayer:onTurnTableEnd()

    --更新状态
    GlobalUserItem.wSeriesDate = GlobalUserItem.wSeriesDate + 1
    GlobalUserItem.bTodayChecked = true

    --统计奖励
    self._logonReward = GlobalUserItem.lCheckinRewards[GlobalUserItem.wSeriesDate]
    self._totalReward = self._drawReward + self._logonReward

    --闪烁选中奖品
    self._spTableItemHighlight:setVisible(true)
    self:runAction(
                    cc.RepeatForever:create(
                        cc.Sequence:create(
                            cc.CallFunc:create(function()
                                
                                if self._spTableItemFlash0:isVisible() then
                                    self._spTableItemFlash0:setVisible(false)
                                    self._spTableItemFlash1:setVisible(true)
                                else
                                    self._spTableItemFlash0:setVisible(true)
                                    self._spTableItemFlash1:setVisible(false)
                                end
                            end),
                            cc.DelayTime:create(0.2)
                        )
                    )
                )

    --显示签到动画和结果页
    self:runAction(cc.Sequence:create( 
                    cc.CallFunc:create(function()
                        --已签到动画
                        self:onCheckedAnimation()   

                        --音效
                        ExternalFun.playPlazaEffect("zhuanzhong.mp3")
                    end),
                    cc.DelayTime:create(2.0),
                    cc.CallFunc:create(function()

                        --更新奖励结果
                        self:onUpdateRewardResult()

                        --显示结果页面
                        self._panelSign:setVisible(false)
                        self._panelResult:setVisible(true)
                    end)
                    )
                )
end

--已签到动画
function LogonRewardLayer:onCheckedAnimation()

    if GlobalUserItem.wSeriesDate < 1 or GlobalUserItem.wSeriesDate > 7 then
        return
    end

    local spGoldItemBg = self._panelSign:getChildByName("sp_gold_item_bg_" .. GlobalUserItem.wSeriesDate)
    local spReceived = spGoldItemBg:getChildByName("sp_received")

    spReceived:setVisible(true)
    spReceived:setScale(2.0)

    spReceived:runAction(cc.Sequence:create(
                            cc.CallFunc:create(function()
                                
                                --更新签到信息
                                self:onUpdateSignInfo()
                            end),
                            cc.ScaleTo:create(0.5, 1.0),
                            cc.DelayTime:create(0.5)
                            )
                        )
end

--点击抽奖
function LogonRewardLayer:onClickDraw()

    --播放音效
    ExternalFun.playClickEffect()

    self._btnDraw:setEnabled(false)

    self:requestLotteryStart()

--    self:onTurnTableBegin(2)

--    self._lotteryResult = {
--        ItemIndex = 2,
--        ItemQuota = 200
--    }
end

--点击领取
function LogonRewardLayer:onClickReceive()

    showPopupLayer(
        RewardShowLayer:create(RewardType.Gold, self._totalReward, function()
            dismissPopupLayer(self)
        end), true, false
    )
end

--------------------------------------------------------------------------------------------------------------------
-- 网络请求

--开始抽奖
function LogonRewardLayer:requestLotteryStart()
    
    showPopWait()

    local ostime = os.time()
    local url = yl.HTTP_URL .. "/WS/Lottery.ashx"   
    --local url = "http://localhost:12569/WS/Lottery.ashx"           
    appdf.onHttpJsionTable(url ,"GET","action=LotteryStart&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime),function(jstable,jsdata)
        
        dismissPopWait()

        local msg = "抽奖异常"
        if type(jstable) == "table" then
            msg = jstable["msg"]
            local data = jstable["data"]
            if type(data) == "table" then
                local valid = data["valid"]
                if nil ~= valid and true == valid then
                    local list = data["list"]
                    if type(list) == "table" then

                        local idx = list["ItemIndex"]
                        msg = nil
                        if nil ~= idx then
                            
                            --保存抽奖数据
                            self._itemIndex = idx
                            self._drawReward = list["ItemQuota"]

                            --保存财富数据
                            GlobalUserItem.lUserScore = list["Score"]
                            GlobalUserItem.dUserBeans = list["Currency"]
                            GlobalUserItem.lUserIngot = list["UserMedal"]

                            --隐藏关闭按钮
                            self._btnClose:setVisible(false)

                            --转盘开始
                            self:onTurnTableBegin(idx)
                        else
                            msg = "抽奖异常"
                        end                        
                    end
                end
            end
        end
        
        if nil ~= msg then
            showToast(self, msg, 2)
            self._btnDraw:setEnabled(true)
        end
    end) 

end

return LogonRewardLayer