
-- 私人房网络处理
local BaseFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BaseFrame")
local PrivateFrame = PrivateFrame or class("PrivateFrame", BaseFrame)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local cmd_private = appdf.req(appdf.PRIVATE_SRC .. "header.CMD_Private")
local define_private = appdf.req(appdf.PRIVATE_SRC .. "header.Define_Private")
local struct_private = appdf.req(appdf.PRIVATE_SRC .. "header.Struct_Private")

-- 登陆服务器CMD
local cmd_pri_login = cmd_private.login
-- 游戏服务器CMD
local cmd_pri_game = cmd_private.game

PrivateFrame.OP_QUERYGAMESERVER = cmd_pri_login.SUB_MB_QUERY_GAME_SERVER            -- 查询私人房服务器
PrivateFrame.OP_SEARCHROOM = cmd_pri_login.SUB_MB_SEARCH_SERVER_TABLE               -- 查询房间
PrivateFrame.OP_ROOMPARAM = cmd_pri_login.SUB_MB_GET_PERSONAL_PARAMETER             -- 私人房配置
PrivateFrame.OP_QUERYLIST = cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST           -- 私人房列表
PrivateFrame.OP_DISSUMEROOM = cmd_pri_login.SUB_MB_DISSUME_SEARCH_SERVER_TABLE      -- 解散桌子
PrivateFrame.OP_QUERYJOINLIST = cmd_pri_login.SUB_GR_USER_QUERY_ROOM_SCORE          -- 查询参与列表
PrivateFrame.OP_EXCHANGEROOMCARD = cmd_pri_login.SUB_MB_ROOM_CARD_EXCHANGE_TO_SCORE -- 房卡兑换游戏币

function PERSONAL_SERVICE_CMD(code)
    return { m = cmd_pri_login.MDM_MB_PERSONAL_SERVICE, s = code }
end
function PERSONAL_TABLE_CMD(code)
    return { m = cmd_pri_game.MDM_GR_PERSONAL_TABLE, s = code }
end

function PrivateFrame:ctor(view, kindid, callbcak)
    PrivateFrame.super.ctor(self, view, callbcak)
    self._wKindID = kindid
end

--连接结果
function PrivateFrame:onConnectCompeleted()
    print("================== PrivateFrame:onConnectCompeleted ================== ==> " .. self._oprateCode)
    if self._oprateCode == PrivateFrame.OP_ROOMPARAM then               -- 私人房配置
        self:sendQueryRoomParam()
    elseif self._oprateCode == PrivateFrame.OP_QUERYGAMESERVER then         -- 查询私人房服务器
        self:sendQueryGameServer()
    elseif self._oprateCode == PrivateFrame.OP_CREATEROOM then          -- 创建房间
        self:sendCreateRoom()
    elseif self._oprateCode == PrivateFrame.OP_SEARCHROOM then          -- 查询房间
        self:sendSearchRoom()
    elseif self._oprateCode == PrivateFrame.OP_QUERYLIST then           -- 请求私人房列表
        self:sendQueryRoomList()
    elseif self._oprateCode == PrivateFrame.OP_QUERYJOINLIST then       -- 参与列表
        self:sendQueryJoinRoomList()
    elseif self._oprateCode == PrivateFrame.OP_DISSUMEROOM then         -- 解散桌子
        self:sendDissumeRoom()
    elseif self._oprateCode == PrivateFrame.OP_EXCHANGEROOMCARD then    -- 房卡兑换游戏币
        self:sendExchangeScore()
    else
        self:onCloseSocket()
        if nil ~= self._callBack then
            self._callBack(PERSONAL_SERVICE_CMD(-1),"未知操作模式！")
        end 
    end
end

--网络信息(短连接)
function PrivateFrame:onSocketEvent( main,sub,pData )
    print("PrivateFrame:onSocketEvent ==> " .. main .. "##" .. sub)

    if cmd_pri_login.MDM_MB_PERSONAL_SERVICE == main then
        if cmd_pri_login.SUB_MB_SEARCH_RESULT == sub then                           -- 房间搜索结果
            self:onSubSearchRoomResult(pData)
        elseif cmd_pri_login.SUB_MB_DISSUME_SEARCH_RESULT == sub then               -- 解散搜索结果
            self:onSubDissumeSearchReasult(pData)
        elseif cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST_RESULT == sub then     -- 私人房列表
            self:onSubPrivateRoomList(pData)
        elseif cmd_pri_login.SUB_GR_USER_QUERY_ROOM_SCORE_RESULT == sub then        -- 参与列表
            self:onSubJoinRoomList(pData)
        elseif cmd_pri_login.SUB_MB_PERSONAL_PARAMETER == sub then                  -- 私人房间属性
            self:onSubRoomParam(pData)
        elseif cmd_pri_login.SUB_MB_PERSONAL_FEE_PARAMETER == sub then              -- 私人房费用配置
            self:onSubRoomFeeParam(pData)
        elseif cmd_pri_login.SUB_MB_QUERY_GAME_SERVER_RESULT == sub then            -- 创建结果
            self:onSubQueryGameServerResult(pData)
        elseif cmd_pri_login.SUB_GP_EXCHANGE_ROOM_CARD_RESULT == sub then           -- 房卡兑换游戏币结果
            self:onSubExchangeRoomCardResult(pData)
        end
    end    
end

------------------------------------------------------------------------------------------------------------
--功能函数 

-- 私人房间配置
function PrivateFrame:onQueryRoomParam()

    local roomParam = GlobalUserItem.tabRoomParamCache[wKindID]
    local roomFeeParam = GlobalUserItem.tabRoomFeeParamCache[wKindID]

    --使用缓存
    if personalParam and personalFeeParam then
        
        if self._viewFrame and self._viewFrame.onGetRoomParam then
            self._viewFrame:onGetRoomParam(roomParam)
        end
        if self._viewFrame and self._viewFrame.onGetRoomFeeParam then
            self._viewFrame:onGetRoomFeeParam(roomFeeParam)
        end

        return
    end

    --操作记录
    self._oprateCode = PrivateFrame.OP_ROOMPARAM
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"建立连接失败！")
    end
end

--查询私人房服务器
function PrivateFrame:onQueryGameServer(cbIsJoinGame)

    self._cbIsJoinGame = cbIsJoinGame

    --操作记录
    self._oprateCode = PrivateFrame.OP_QUERYGAMESERVER
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"建立连接失败！")
    end
end

--查询私人房创建列表
function PrivateFrame:onQueryRoomList()

    --操作记录
    self._oprateCode = PrivateFrame.OP_QUERYLIST
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"建立连接失败！")
    end
end

--查询私人房参与列表
function PrivateFrame:onQueryJoinList()
    --操作记录
    self._oprateCode = PrivateFrame.OP_QUERYJOINLIST
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"建立连接失败！")
    end
end

--查询房间
function PrivateFrame:onSearchRoom( roomId )
    --操作记录
    self._oprateCode = PrivateFrame.OP_SEARCHROOM
    self._roomId = roomId or ""
    if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"建立连接失败！")
    end
end

--获取我的成绩
function PrivateFrame:getMyReword( list )
    if type(list) ~= "table" then
        return 0
    end
    for k,v in pairs(list) do
        if v["dwUserID"] == GlobalUserItem.dwUserID then
            return (tonumber(v.lScore) or 0)
        end
    end
    return 0
end

------------------------------------------------------------------------------------------------------------

-- 发送请求配置
function PrivateFrame:sendQueryRoomParam()

    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_GetPersonalParameter)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE, cmd_pri_login.SUB_MB_GET_PERSONAL_PARAMETER)
    buffer:pushdword(self._wKindID)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"发送请求配置失败！")
    end
end

--发送查询私人房服务器
function PrivateFrame:sendQueryGameServer()

    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_QueryGameServer)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_QUERY_GAME_SERVER)
    buffer:pushdword(GlobalUserItem.dwUserID)
    buffer:pushdword(self._wKindID)
    buffer:pushbyte(self._cbIsJoinGame)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"发送查询房间失败！")
    end
end

-- 发送查询私人房列表
function PrivateFrame:sendQueryRoomList()
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_QeuryPersonalRoomList)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST)
    buffer:pushdword(GlobalUserItem.dwUserID)
    buffer:pushdword(self._wKindID)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"发送查询房间列表失败！")
    end
end

-- 发送查询参与列表
function PrivateFrame:sendQueryJoinRoomList()
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_QeuryPersonalRoomList)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_GR_USER_QUERY_ROOM_SCORE)
    buffer:pushdword(GlobalUserItem.dwUserID)
    buffer:pushdword(self._wKindID)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"发送查询参与列表失败！")
    end
end

-- 发送查询私人房
function PrivateFrame:sendSearchRoom()
    local buffer = ExternalFun.create_netdata(cmd_pri_login.CMD_MB_SerchServerTableEnter)
    buffer:setcmdinfo(cmd_pri_login.MDM_MB_PERSONAL_SERVICE,cmd_pri_login.SUB_MB_SEARCH_SERVER_TABLE)
    buffer:pushstring(self._roomId, define_private.ROOM_ID_LEN)
    buffer:pushdword(self._wKindID)
    if not self:sendSocketData(buffer) and nil ~= self._callBack then
        self._callBack(PERSONAL_SERVICE_CMD(-1),"发送查询房间失败！")
    end
end

------------------------------------------------------------------------------------------------------------
-- 网络事件处理

--房间参数
function PrivateFrame:onSubRoomParam(pData)

    local param = ExternalFun.read_netdata( struct_private.tagPersonalRoomOption, pData )

    --保存参数
    GlobalUserItem.tabRoomParamCache[self._wKindID] = param

    if self._viewFrame and self._viewFrame.onGetRoomParam then
        self._viewFrame:onGetRoomParam(param)
    end
end

--房间费用参数
function PrivateFrame:onSubRoomFeeParam(pData)

    local roomFeeParam = {}

    local len = pData:getlen()
    local count = math.floor(len/define_private.LEN_PERSONAL_TABLE_PARAMETER)
    for idx = 1, count do
        local param = ExternalFun.read_netdata( struct_private.tagPersonalTableParameter, pData )
        table.insert(roomFeeParam, param)
    end
    table.sort( roomFeeParam, function(a, b)
        return a.dwDrawCountLimit < b.dwDrawCountLimit
    end )
    
    --保存参数
    GlobalUserItem.tabRoomFeeParamCache[self._wKindID] = roomFeeParam

    if self._viewFrame and self._viewFrame.onGetRoomFeeParam then
        self._viewFrame:onGetRoomFeeParam(roomFeeParam)
    end

    --关闭连接
    self:onCloseSocket()
end

--查询私人房服务器结果
function PrivateFrame:onSubQueryGameServerResult(pData)

    local cmd_table = ExternalFun.read_netdata( cmd_pri_login.CMD_MB_QueryGameServerResult, pData )
    local tips = cmd_table.szErrDescrybe
    
    if nil ~= self._callBack and type(tips) == "string" and tips ~= "" then
        self._callBack(PERSONAL_SERVICE_CMD(-1), tips)
        return
    end

    if cmd_table.dwServerID == 0 or cmd_table.bCanCreateRoom == false then
        self._callBack(PERSONAL_SERVICE_CMD(-1), "创建私人房失败")
        return
    end

    if self._viewFrame and self._viewFrame.onGetGameServer then
        self._viewFrame:onGetGameServer(cmd_table.dwServerID)
    end

    --关闭连接
    self:onCloseSocket()
end

-- 私人房列表
function PrivateFrame:onSubPrivateRoomList( pData )
    
    local tabRoomList = {}

    local cmd_table = ExternalFun.read_netdata(cmd_pri_login.CMD_MB_PersonalRoomInfoList, pData)
    local listinfo = cmd_table.PersonalRoomInfo[1]
    for i = 1, define_private.MAX_CREATE_PERSONAL_ROOM do
        local info = listinfo[i]
        if info.szRoomID ~= "" then
            info.lScore = info.lTaxCount--self:getMyReword(info.PersonalUserScoreInfo[1])
            -- 时间戳
            local tt = info.sysDissumeTime
            info.dissumeTimeStamp = os.time({day=tt.wDay, month=tt.wMonth, year=tt.wYear, hour=tt.wHour, min=tt.wMinute, sec=tt.wSecond})
            tt = info.sysCreateTime
            info.createTimeStamp = os.time({day=tt.wDay, month=tt.wMonth, year=tt.wYear, hour=tt.wHour, min=tt.wMinute, sec=tt.wSecond})
            table.insert(tabRoomList, info)
        else
            break
        end
    end
    table.sort(tabRoomList, function(a, b)
        if a.cbIsDisssumRoom ~= b.cbIsDisssumRoom then
            return a.cbIsDisssumRoom < b.cbIsDisssumRoom
        else
            if a.cbIsDisssumRoom == 0 then
                return a.createTimeStamp > b.createTimeStamp
            else
                return a.dissumeTimeStamp > b.dissumeTimeStamp
            end
        end        
    end )

    --关闭连接
    self:onCloseSocket()

    if self._viewFrame and self._viewFrame.onGetRoomList then
        self._viewFrame:onGetRoomList(tabRoomList)
    end
end

-- 参与列表
function PrivateFrame:onSubJoinRoomList( pData )
    
    local tabJoinRoomList = {}

    -- 计算数目
    local len = pData:getlen()
    local itemcount = math.floor(len/define_private.LEN_PERSONAL_ROOM_SCORE)

    for i = 1, itemcount do
        local pServer = ExternalFun.read_netdata(struct_private.tagQueryPersonalRoomUserScore, pData)
        pServer.lScore = self:getMyReword(pServer["PersonalUserScoreInfo"][1])
        -- 时间戳
        local tt = pServer.sysDissumeTime
        pServer.sortTimeStmp = os.time({day=tt.wDay, month=tt.wMonth, year=tt.wYear, hour=tt.wHour, min=tt.wMinute, sec=tt.wSecond}) or 0
        pServer.bFlagOnGame = (pServer.sortTimeStmp == 0)
        pServer.nOnGameOrder = pServer.bFlagOnGame and 1 or 0
        tt = pServer.sysCreateTime
        pServer.sortCreateTimeStmp = os.time({day=tt.wDay, month=tt.wMonth, year=tt.wYear, hour=tt.wHour, min=tt.wMinute, sec=tt.wSecond}) or 0
        table.insert(tabJoinRoomList, pServer)        
    end
    table.sort(tabJoinRoomList, function(a, b)
        if a.bFlagOnGame ~= b.bFlagOnGame then
            if a.nOnGameOrder == b.nOnGameOrder then
                return a.sortCreateTimeStmp < b.sortCreateTimeStmp
            else
                return a.nOnGameOrder < b.nOnGameOrder
            end
        else
            return a.sortTimeStmp < b.sortTimeStmp
        end
    end )

    --关闭连接
    self:onCloseSocket()

    if self._viewFrame and self._viewFrame.onGetJoinRoomList then
        self._viewFrame:onGetJoinRoomList(tabJoinRoomList)
    end
end

-- 房间搜索结果
function PrivateFrame:onSubSearchRoomResult( pData )

    local cmd_table = ExternalFun.read_netdata(cmd_pri_login.CMD_MB_SearchResult, pData)

    if 0 == cmd_table.dwServerID then
        if nil ~= self._callBack then
            self._callBack(PERSONAL_SERVICE_CMD(cmd_pri_login.SUB_MB_SEARCH_RESULT), "该房间ID不存在, 请重新输入!")
        end
        return
    end

    if self._viewFrame and self._viewFrame.onGetSearchRoomResult then
        self._viewFrame:onGetSearchRoomResult(cmd_table)
    end
end

return PrivateFrame