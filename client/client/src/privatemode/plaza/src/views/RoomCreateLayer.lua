--创建房间界面
local RoomCreateLayer = class("RoomCreateLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local ActivityIndicator = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.general.ActivityIndicator")
local RoomLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.room.RoomLayer")
local ShopLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ShopLayer")

--私人房网络框架
local PrivateFrame = appdf.req(appdf.PRIVATE_SRC .. "plaza.src.models.PrivateFrame")

--私人房命令
local cmd_private = appdf.req(appdf.CLIENT_SRC .. "privatemode.header.CMD_Private")
local cmd_pri_game = cmd_private.game

function RoomCreateLayer:ctor(wKindID)

    --保存参数
    self._wKindID = wKindID

    --初始化参数
    self._roomLayer = RoomLayer:getInstance()

    --网络处理
    self._privateFrame = PrivateFrame:create(self, wKindID, function(result, message)
        self:onPrivateFrameCallBack(result, message)
    end)

    --事件监听
    self:initEventListener()

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Room/PrivateMode/RoomCreateLayer.csb"):addTo(self)
    local content = csbNode:getChildByName("content")

    content:getChildByName("btn_close"):addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --购买
    local btnBuy = content:getChildByName("btn_buy")
    btnBuy:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        --dismissPopupLayer(self)

        local scene = cc.Director:getInstance():getRunningScene()
        ShopLayer:create(3):addTo(scene)
    end)

    --创建房间
    local btnCreate = content:getChildByName("btn_create")
    btnCreate:addClickEventListener(function()

        self:onClickCreate()
    end)

    --房卡数量
    self._txtRoomCard = content:getChildByName("txt_roomcard")
    self:onUpdateRoomCard()

    --滚动视图
    self._scrollView = content:getChildByName("scrollview")
    self._scrollView:setBackGroundColorType(ccui.LayoutBackGroundColorType.none)
    self._scrollView:setScrollBarEnabled(false)

    --活动指示器
    self._activity = ActivityIndicator:create()
    self._activity:setPosition(self._scrollView:getPosition())
    self._activity:addTo(content, 100)

    --获取房间参数
    self._privateFrame:onQueryRoomParam()

    --内容跳入
    AnimationHelper.jumpIn(content)
end

--初始化事件监听
function RoomCreateLayer:initEventListener()

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

    --用户信息改变事件
    eventDispatcher:addEventListenerWithSceneGraphPriority(
        cc.EventListenerCustom:create(yl.RY_USERINFO_NOTIFY, handler(self, self.onUserInfoChange)),
        self
        )

    --私人桌事件
    eventDispatcher:addEventListenerWithSceneGraphPriority(
        cc.EventListenerCustom:create(yl.RY_PERSONAL_TABLE_NOTIFY, handler(self, self.onEventPersonalTable)),
        self
        )
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

function RoomCreateLayer:onExit()
    
    if self._privateFrame:isSocketServer() then
        self._privateFrame:onCloseSocket()
    end
end

--用户信息改变
function RoomCreateLayer:onUserInfoChange(event)
    
    print("----------RoomCreateLayer:onUserInfoChange------------")

	local msgWhat = event.obj
	if nil ~= msgWhat then

        if msgWhat == yl.RY_MSG_USERWEALTH then
		    --更新房卡
		    self:onUpdateRoomCard()
        end
	end
end

--私人桌事件
function RoomCreateLayer:onEventPersonalTable(event)
    
    local cmd = event.cmd
    local data = event.data

    if cmd == cmd_pri_game.SUB_GR_CREATE_SUCCESS then

    end
end

--更新房卡信息
function RoomCreateLayer:onUpdateRoomCard()
    
    self._txtRoomCard:setString(GlobalUserItem.lRoomCard)
end

--创建房间
function RoomCreateLayer:onClickCreate()

    --播放音效
    ExternalFun.playClickEffect()

    if self._detailParamLayer == nil then
        return
    end

    --检查数据有效性
    local message = self._detailParamLayer:checkDetailParamValues()
    if type(message) == "string" and message ~= "" then
        showToast(nil, message, 1)
        return
    end

    --查询私人房服务器
    self._privateFrame:onQueryGameServer(self._roomParam.cbIsJoinGame)
end

------------------------------------------------------------------------------------------------------------
-- 功能函数

--获取游戏私人房创建层
function RoomCreateLayer:getPriRoomCreateLayer()

    --获取游戏参数
    local gameInfo = MyApp:getInstance():getGameInfo(self._wKindID)
    if gameInfo == nil then
        return nil
    end

    local PriRoomCreateLayer = appdf.req(appdf.GAME_SRC .. gameInfo._KindName .. "src.privateroom.PriRoomCreateLayer")
    return PriRoomCreateLayer
end

------------------------------------------------------------------------------------------------------------
-- PrivateFrame 回调

function RoomCreateLayer:onPrivateFrameCallBack(result, message)

    dismissPopWait()

    if type(message) == "string" and message ~= "" then
        showToast(nil, message, 2)
    end
end

--获取到房间参数
function RoomCreateLayer:onGetRoomParam(param)

    self._roomParam = param
end

--获取到房间费用参数
function RoomCreateLayer:onGetRoomFeeParam(param)

    self._activity:stop()

    self._roomFeeParam = param

    local PriRoomCreateLayer = self:getPriRoomCreateLayer()
    if PriRoomCreateLayer == nil then
        return
    end

    --创建参数页面
    self._detailParamLayer = PriRoomCreateLayer:create(self._roomParam, self._roomFeeParam)
    self._detailParamLayer:setAnchorPoint(0, 1)
    self._detailParamLayer:addTo(self._scrollView)

    local scrollViewSize = self._scrollView:getContentSize()
    local paramLayerSize = self._detailParamLayer:getContentSize()

    if paramLayerSize.height < scrollViewSize.height then
        self._detailParamLayer:setPosition(0, scrollViewSize.height)
        self._scrollView:setInnerContainerSize(scrollViewSize)
        self._scrollView:setBounceEnabled(false)
    else
        self._detailParamLayer:setPosition(0, paramLayerSize.height)
        self._scrollView:setInnerContainerSize(cc.size(scrollViewSize.width, paramLayerSize.height))
        self._scrollView:setBounceEnabled(true)
    end
end

--获取到私人房服务器
function RoomCreateLayer:onGetGameServer(wServerID)

    --登录私人房
    self._roomLayer:logonPrivateRoom(self._wKindID, wServerID, function()

        --创建桌子
        local data = self._detailParamLayer:getCreateTableData()
        self._roomLayer:createTable(data)
    end)
end

return RoomCreateLayer