--房间控制器

local RoomLayer = class("RoomLayer", cc.Layer)

local QueryDialog = appdf.req(appdf.BASE_SRC .. "app.views.layer.other.QueryDialog")

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local GameFrameEngine = appdf.req(appdf.CLIENT_SRC.."plaza.models.GameFrameEngine")

local RoomViewLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.room.RoomViewLayer")
local UserInfoLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.UserInfoLayer")
local TablePasswordLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.TablePasswordLayer")

local GameScene = appdf.req(appdf.CLIENT_SRC.."plaza.views.GameScene")

--私人房命令
local cmd_private = appdf.req(appdf.CLIENT_SRC .. "privatemode.header.CMD_Private")
local cmd_pri_game = cmd_private.game

--当前平台
local targetPlatform = cc.Application:getInstance():getTargetPlatform()

--映射函数
local MAP_FUNC_NAMES = { 
    "onExitTable",
    "onEventGameScene",
    "onEventUserScore",
    "onEventGameMessage",
    "onSocketInsureEvent",
    "onUserChat",
    "onUserExpression",
    "onUserVoiceStart",
    "onUserVoiceEnded",
    "OnResetGameEngine"
}

RoomLayer._instance = nil

function RoomLayer:getInstance()
    return RoomLayer._instance
end

function RoomLayer:ctor(delegate)

    RoomLayer._instance = self

    --保存数据
    self._delegate = delegate

    --创建游戏框架
    self._gameFrame = GameFrameEngine:create(self, function(result, message)
        self:onGameFrameCallBack(result, message)
    end)
    self._gameFrame:setViewFrame(self)

    local contentSize = self:getContentSize()

    --锁桌按钮
    self._btnLock = ccui.Button:create("Room/bt_lock_0.png", "Room/bt_lock_1.png")
    self._btnLock:setPosition(50, 620)
    self._btnLock:setScale(0.8)
    self._btnLock:setVisible(false)
    self._btnLock:addTo(self, 100)
    self._btnLock:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickTableLock()
    end)

    --快速加入按钮
    self._btnQuickJoin = ccui.Button:create("Room/bt_quick_join_0.png", "Room/bt_quick_join_1.png")
    self._btnQuickJoin:setAnchorPoint(1, 0.5)
    self._btnQuickJoin:setPosition(contentSize.width, contentSize.height / 2)
    self._btnQuickJoin:setVisible(false)
    self._btnQuickJoin:addTo(self, 100)
    self._btnQuickJoin:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickQuickJoin()
    end)

    --映射函数
    for i = 1, #MAP_FUNC_NAMES do
        local func_name = MAP_FUNC_NAMES[i]
        if self[func_name] == nil then 
            self[func_name] = function(...)
                local gameLayer = self:getGameLayer()
                if gameLayer then
                    local func = gameLayer[func_name]
                    if func then
                        func(gameLayer, unpack({...}, 2))
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击锁桌
function RoomLayer:onClickTableLock()

    if self._gameFrame:isSocketServer() then
        
        showPopupLayer(TablePasswordLayer:create(function(password)
                
            if password ~= nil and password ~= "" then
                --发送密码
                self._gameFrame:SendEncrypt(password)
            end
        end))
    end
end

--点击快速加入
function RoomLayer:onClickQuickJoin()

    if self._gameFrame:QueryChangeDesk() then
        showPopWait()
    end
end

------------------------------------------------------------------------------------------------------------
-- 房间操作

--重置房间
function RoomLayer:resetRoom()

    --清空信息
    self._gameInfo = nil
    self._roomInfo = nil

    --隐藏按钮
    self._btnLock:setVisible(false)
    self._btnQuickJoin:setVisible(false)
end

--登录房间
function RoomLayer:logonRoom(wKindID, wServerID)

    --获取游戏信息
    local gameInfo = MyApp:getInstance():getGameInfo(wKindID)
    if nil == gameInfo then
        print("游戏信息不存在", wKindID)
        return
    end

    --获取房间信息
    local roomInfo = GlobalUserItem.getGameRoomInfo(wKindID, wServerID)
    if nil == roomInfo then
        print("房间信息不存在", wServerID)
        return
    end

    --重置房间
    self:resetRoom()

    --保存信息
    self._gameInfo = gameInfo
    self._roomInfo = roomInfo

    GlobalUserItem.tabEnterGame = gameInfo
    GlobalUserItem.tabEnterRoom = roomInfo
    GlobalUserItem.bPrivateRoom = self:isPrivateRoom()

    showPopWait()

    --发起连接
    self._gameFrame:onCloseSocket()
    self._gameFrame:onInitData()
	self._gameFrame:setKindInfo(gameInfo._KindID, gameInfo._KindVersion)
	self._gameFrame:onLogonRoom(roomInfo)
end

--登录私人房
function RoomLayer:logonPrivateRoom(wKindID, wServerID, logonCallBack)

    self._privateLogonCallBack = logonCallBack

    self:logonRoom(wKindID, wServerID)
end

--关闭房间
function RoomLayer:closeRoom()

    --退出房间
    self:onExitRoom()
end

--关闭游戏
function RoomLayer:closeGame()

    if self._gameScene then
        
        --self._delegate:getApp():popScene()
        self._gameScene:removeFromParent()
        self._gameScene = nil

        --AudioEngine.stopMusic()

        dismissPopWait()
    end
end

--创建桌子
function RoomLayer:createTable(data)

    self._gameFrame:sendSocketData(data)
end

------------------------------------------------------------------------------------------------------------
-- 功能函数

--是否是私人房
function RoomLayer:isPrivateRoom()
    
    if self._roomInfo and self._roomInfo.wServerType == yl.GAME_GENRE_PERSONAL then
        return true
    end

    return false
end

--是否进入了房间
function RoomLayer:isEnterRoom()

    return self._gameFrame:isSocketServer()
end

--开始保持活动连接
function RoomLayer:startKeepAlive()

    if self._scheduleKeepAlive then
        return
    end

    print("开始保持活动连接")

    --定时发送内核检测数据（手机版在收到内核检测后，没有主动回复，所以在这里定时发送防止掉线）
    self._scheduleKeepAlive = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()

        if self._gameFrame:isSocketServer() then

            print("发送心跳检测包...")

            local dataBuffer = CCmd_Data:create(0)
	        dataBuffer:setcmdinfo(0,1)
            self._gameFrame:sendSocketData(dataBuffer)
        end
    end, 5, false)
end

--停止保持活动连接
function RoomLayer:stopKeepAlive()
    
    if self._scheduleKeepAlive then
        
        print("停止保持活动连接")

        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._scheduleKeepAlive) 
        self._scheduleKeepAlive = nil
    end
end

--添加搜索路径
function RoomLayer:addSearchPath()

    local gameInfo = self._gameInfo

    if nil ~= gameInfo then
        local searchPath = device.writablePath.."game/" .. gameInfo._Module .. "/res/";
        cc.FileUtils:getInstance():addSearchPath(searchPath);

        print("RoomLayer:addSearchPath( \"" .. searchPath .. "\" )")
    end
end

--移除搜索路径
function RoomLayer:removeSearchPath()

    local gameInfo = self._gameInfo
    local pos = string.find(gameInfo._Module, "/")
    local gamedir = string.sub(gameInfo._Module, pos + 1, -2)

    --重置搜索路径
    local oldPaths = cc.FileUtils:getInstance():getSearchPaths();
    local newPaths = {};
    for k,v in pairs(oldPaths) do
        if string.find(tostring(v), gamedir) == nil then
            table.insert(newPaths, v);
        else
            print("RoomLayer:removeSearchPath( \"" .. v .. "\" )")
        end
    end

    cc.FileUtils:getInstance():setSearchPaths(newPaths);
end

--添加私人房搜索路径
function RoomLayer:addPrivateSearchPath()

    local gameInfo = self._gameInfo

    if nil ~= gameInfo then
        self._priSearchPath = device.writablePath.."game/" .. gameInfo._Module .. "/res/privateroom/";
        cc.FileUtils:getInstance():addSearchPath(self._priSearchPath)

        print("RoomLayer:addPrivateSearchPath( \"" .. self._priSearchPath .. "\" )")
    end   
end

--移除私人房搜索路径
function RoomLayer:removePrivateSearchPath()

    --重置搜索路径
    local oldPaths = cc.FileUtils:getInstance():getSearchPaths()
    local newPaths = {}
    for k,v in pairs(oldPaths) do
        if tostring(v) ~= tostring(self._priSearchPath) then
            table.insert(newPaths, v)
        else
            print("RoomLayer:removePrivateSearchPath( \"" .. v .. "\" )")
        end
    end
    cc.FileUtils:getInstance():setSearchPaths(newPaths)
end

------------------------------------------------------------------------------------------------------------
-- 数据接口

--获取当前游戏信息
function RoomLayer:getEnterGameInfo()
    
    return GlobalUserItem.tabEnterGame
end

--获取桌子信息
function RoomLayer:getTableInfo(wTableID)

    return self._gameFrame:getTableInfo(wTableID)
end

--获取桌子用户信息
function RoomLayer:getTableUserItem(wTableID, wChairID)

    return self._gameFrame:getTableUserItem(wTableID, wChairID)
end

--获取游戏场景
function RoomLayer:getGameScene()
    
    return self._gameScene
end

--获取游戏层
function RoomLayer:getGameLayer()
    
    if self._gameScene == nil then
        return nil
    end

    return self._gameScene:getGameLayer()
end

------------------------------------------------------------------------------------------------------------
-- RoomViewLayer 回调

--点击桌椅
function RoomLayer:onSitDown(wTableID, wChairID)
    
    local userItem = self:getTableUserItem(wTableID, wChairID)

    if userItem then
        
        --显示用户信息
        showPopupLayer(UserInfoLayer:create(userItem))
    else
        
        --获取桌子信息
        local tableInfo = self:getTableInfo(wTableID + 1)
        if tableInfo == nil then
            return
        end

        local sitdown = function(tableid, chairid, pass)

            showPopWait()
            --发送坐下请求
            self._gameFrame:SitDown(wTableID, wChairID, pass)
        end

        --需要输入密码
        if tableInfo.cbTableLock == 1 then
        
            showPopupLayer(TablePasswordLayer:create(function(password)
                
                --坐下
                sitdown(wTableID, wChairID, password)
            end))
        else
            --坐下
            sitdown(wTableID, wChairID)
        end
    end
end

------------------------------------------------------------------------------------------------------------
-- GameScene 回调

function RoomLayer:onKeyBack()

    self:closeGame()

    --如果是直接进入的类型，关闭房间
    if self._roomViewLayer == nil then
        self:closeRoom()
    end
end

------------------------------------------------------------------------------------------------------------
-- GameFrameEngine 回调

function RoomLayer:onGameFrameCallBack(result, message)

    local bClose = false

    if type(result) == "table" then

        local main = result.m
        local sub = result.s
        local data = message

        --私人房命令
        if main == cmd_pri_game.MDM_GR_PERSONAL_TABLE then
            
            if type(message) == "string" and message ~= "" then

                QueryDialog:create(message, nil, nil, QueryDialog.QUERY_SURE)
	                        :addTo(self._delegate)

                bClose = true
            end

            if sub == cmd_pri_game.SUB_GR_CREATE_SUCCESS then               --创建成功
                bClose = true
            elseif sub == cmd_pri_game.SUB_GR_PERSONAL_TABLE_TIP then       --私人房数据
                --刷新私人房数据
                if self._priGameLayer ~= nil then
                    self._priGameLayer:onRefreshInfo()
                end
            end

            -- 通知私人房事件      
            local eventListener = cc.EventCustom:new(yl.RY_PERSONAL_TABLE_NOTIFY)
            eventListener.obj = { cmd = sub, data = message }
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)

        end
    else

        if type(message) == "string" and message ~= "" then

            QueryDialog:create(message, nil, nil, QueryDialog.QUERY_SURE)
	                        :addTo(self._delegate)
        end

        bClose = true
    end

    --关闭房间
    if bClose then

        dismissPopWait()

        self:onExitRoom(-1)
    end
end

--进入房间
function RoomLayer:onEnterRoom()
    
    print("RoomLayer:onEnterRoom()")

    --添加游戏搜索路径
    self:addSearchPath()

    --添加私人房搜索路径
    if self:isPrivateRoom() then
        self:addPrivateSearchPath()
    end

    --私人房登录回调
    if self._privateLogonCallBack then
        self._privateLogonCallBack()
        self._privateLogonCallBack = nil
        return
    end

    --开始保持活动连接
    self:startKeepAlive()

    dismissPopWait()

    --通知进入房间
    if self._delegate and self._delegate.onEnterRoom then
        self._delegate:onEnterRoom()
    end 

    local bAutoJoin = false
    bAutoJoin = bAutoJoin or GlobalUserItem.isAntiCheat()               --防作弊
    bAutoJoin = bAutoJoin or self._gameFrame:GetChairCount() >= 100     --百人游戏
    bAutoJoin = bAutoJoin or (self._roomInfo.wServerLevel >= 10)         --快速场

    --直接进入游戏
    if bAutoJoin then

        local wTableID = self._gameFrame:GetTableID()
        local wChairID = self._gameFrame:GetChairID()

		if wTableID == yl.INVALID_TABLE and wChairID == yl.INVALID_CHAIR and self._gameFrame:QueryChangeDesk() then
			showPopWait()
		end
		return
    end

	--自定义房间界面处理登陆成功消息
	local modulestr = string.gsub(self._gameInfo._KindName, "%.", "/")
	local customRoomFile = ""
	if cc.PLATFORM_OS_WINDOWS == targetPlatform then
		customRoomFile = "game/" .. modulestr .. "src/views/GameRoomListLayer.lua"
	else
		customRoomFile = "game/" .. modulestr .. "src/views/GameRoomListLayer.luac"
	end
	if cc.FileUtils:getInstance():isFileExist(customRoomFile) then
		if (appdf.req(customRoomFile):onEnterRoom(self._gameFrame)) then
			showPopWait()
		else
            showToast(nil, "进入房间失败", 2)
			--退出房间
            self:closeRoom()
		end
    else
        --普通房间，创建房间视图
        if self._roomViewLayer then
            self._roomViewLayer:removeFromParent()
        end

        self._roomViewLayer = RoomViewLayer:create(self):addTo(self)
	end
end

--离开房间
function RoomLayer:onExitRoom(code, message)

    print("RoomLayer:onExitRoom()")
    
    --显示大厅
    self._delegate:setVisible(true)

    --停止保持活动连接
    self:stopKeepAlive()

    --关闭游戏
    self:closeGame()

    --关闭连接
    if self._gameFrame:isSocketServer() then
        self._gameFrame:onCloseSocket()
    end

    --清理游戏搜索路径
    self:removeSearchPath()

    --私人房
    if self:isPrivateRoom() then
        --清理搜索路径
        self:removePrivateSearchPath()
        --清理房间数据
        GlobalUserItem.tabPriRoomData = {}
        GlobalUserItem.bPrivateRoom = false
    end

    --重置游戏包
	for k ,v in pairs(package.loaded) do
		if k ~= nil then 
			if type(k) == "string" then
				if string.find(k,"game.qipai.") ~= nil or string.find(k,"game.yule.") ~= nil then
					print("package kill:"..k) 
					package.loaded[k] = nil
				end
			end
		end
	end	

    --清理游戏信息
    GlobalUserItem.tabEnterGame = nil

    --更新房间人数
--    self._roomInfo.dwOnLineCount = self._gameFrame:GetOnlineCount()
--    self._roomInfo.dwAndroidCount = 0

    --移除房间视图
    if self._roomViewLayer then
        self._roomViewLayer:removeFromParent()
        self._roomViewLayer = nil
    end

    --通知离开房间
    if self._delegate and self._delegate.onExitRoom then
        self._delegate:onExitRoom(code, message)
    end

    --重置房间
    self:resetRoom()
end

--进入桌子
function RoomLayer:onEnterTable()

    print("RoomLayer:onEnterTable(" .. self._gameFrame:GetTableID() .. ", " .. self._gameFrame:GetChairID() .. ")")

    dismissPopWait()

    --通知进入桌子
    if self._delegate and self._delegate.onEnterTable then
        self._delegate:onEnterTable()
    end

    if self._gameScene == nil then

        self._gameScene = GameScene:create(self)
        self._gameScene:addTo(cc.Director:getInstance():getRunningScene())

        self._gameFrame:SendGameOption()

        --隐藏大厅
        self._delegate:setVisible(false)

--        --进入游戏场景
--        self._delegate:getApp():pushScene(appdf.CLIENT_SRC.."plaza.views.GameScene",nil,0,nil,function(scene)
--            self._gameScene = scene
--            self._gameScene:setDelegate(self)

--            --发送游戏选项，获取场景信息
--            self._gameFrame:SendGameOption()

--            --创建游戏层
--            self._gameScene:createGameLayer()

--            --如果是私人房，添加私人房游戏层
--            if self._roomInfo.wServerType == yl.GAME_GENRE_PERSONAL then
--                local modulestr = string.gsub(self._gameInfo._KindName, "%.", "/")
--                local gameFile = ""
--                if cc.PLATFORM_OS_WINDOWS == targetPlatform then
--                    gameFile = "game/" .. modulestr .. "src/privateroom/PriGameLayer.lua"
--                else
--                    gameFile = "game/" .. modulestr .. "src/privateroom/PriGameLayer.luac"
--                end
--                if cc.FileUtils:getInstance():isFileExist(gameFile) then
--                    local gameLayer = self._gameScene:getGameLayer()
--                    local priGameLayer = appdf.req(gameFile):create( gameLayer )
--                    if nil ~= priGameLayer then
--                        gameLayer._gameView:addChild(priGameLayer)
--                        gameLayer._gameView._priView = priGameLayer
--                        self._priGameLayer = priGameLayer

--                        --刷新私人房数据
--                        if next(GlobalUserItem.tabPriRoomData) ~= nil then
--                            self._priGameLayer:onRefreshInfo()
--                        end
--                    end
--                end
--            end
--        end)
    else --换桌

        --发送游戏选项，获取场景信息
        self._gameFrame:SendGameOption()
    end

end

--离开桌子
function RoomLayer:onExitTable()

    --显示大厅
    self._delegate:setVisible(true)

    --通知游戏场景
    local gameLayer = self:getGameLayer()
    if gameLayer and gameLayer.onExitTable then
        gameLayer:onExitTable()
    end

    --通知离开桌子
    if self._delegate and self._delegate.onExitTable then
        self._delegate:onExitTable()
    end
end

--获取到桌子信息
function RoomLayer:onGetTableInfo()

    if self._roomViewLayer ~= nil then

        --创建桌子列表
        self._roomViewLayer:createTableList(self._gameFrame:GetTableCount(), self._gameFrame:GetChairCount())

        --显示按钮
        self._btnLock:setVisible(true)
        self._btnQuickJoin:setVisible(true)
    end
end

--桌子状态
function RoomLayer:onEventTableStatus(wTableID, cbTableStatus)
	
    if self._roomViewLayer ~= nil then
        self._roomViewLayer:updateTable(wTableID)
    end
end

--玩家进入
function RoomLayer:onEventUserEnter(wTableID, wChairID, userItem)
	
    --通知游戏场景
    local gameLayer = self:getGameLayer()
    if gameLayer and gameLayer.onEventUserEnter then
        gameLayer:onEventUserEnter(wTableID, wChairID, userItem)
    end

    if self._roomViewLayer ~= nil and wTableID ~= yl.INVALID_TABLE then
        
        self._roomViewLayer:updateChair(wTableID, wChairID, userItem)
    end
end

--玩家状态
function RoomLayer:onEventUserStatus(userItem, newStatus, oldStatus)
	
    --通知游戏场景
    local gameLayer = self:getGameLayer()
    if gameLayer and gameLayer.onEventUserStatus then
        gameLayer:onEventUserStatus(userItem, newStatus, oldStatus)
    end

    if self._roomViewLayer ~= nil then

        --有三种状态，1.坐下 2.站起 3.换座位

        --坐下
        if oldStatus.wTableID == yl.INVALID_TABLE and newStatus.wTableID ~= yl.INVALID_TABLE then

            self._roomViewLayer:updateChair(newStatus.wTableID, newStatus.wChairID, userItem)

        --站起
        elseif oldStatus.wTableID ~= yl.INVALID_TABLE and newStatus.wTableID == yl.INVALID_TABLE then

            self._roomViewLayer:updateChair(oldStatus.wTableID, oldStatus.wChairID, nil)

        --换桌/换桌位
        elseif oldStatus.wTableID ~= yl.INVALID_TABLE and newStatus.wTableID ~= yl.INVALID_TABLE and (oldStatus.wTableID ~= newStatus.wTableID or oldStatus.wChairID ~= newStatus.wChairID) then

            self._roomViewLayer:updateChair(oldStatus.wTableID, oldStatus.wChairID, nil)
            self._roomViewLayer:updateChair(newStatus.wTableID, newStatus.wChairID, userItem)
        end
    end

end

--用户分数
--function RoomLayer:onEventUserScore(item)

--    --通知游戏场景
--    local gameLayer = self:getGameLayer()
--    if gameLayer and gameLayer.onEventUserScore then
--        gameLayer:onEventUserScore(item)
--    end
--end

--场景信息
--function RoomLayer:onEventGameScene(cbGameStatus,dataBuffer)

--    --通知游戏场景
--    local gameLayer = self:getGameLayer()
--    if gameLayer and gameLayer.onEventGameScene then
--        gameLayer:onEventGameScene(cbGameStatus,dataBuffer)
--    end
--end

--游戏消息
--function RoomLayer:onEventGameMessage(sub,dataBuffer)

--    --通知游戏场景
--    local gameLayer = self:getGameLayer()
--    if gameLayer and gameLayer.onEventGameMessage then
--        gameLayer:onEventGameMessage(sub,dataBuffer)
--    end
--end

--私人桌数据
function RoomLayer:onEventPersonalTable(sub,pData)


end

--请求失败
function RoomLayer:onRequestFailure(code, message)

    dismissPopWait()

    if type(message) == "string" and message ~= "" then
        showToast(nil, message, 2)
    end
end

return RoomLayer