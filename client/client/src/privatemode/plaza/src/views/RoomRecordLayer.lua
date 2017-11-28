--房间记录界面
local RoomRecordLayer = class("RoomRecordLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local ActivityIndicator = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.general.ActivityIndicator")

local PrivateFrame = appdf.req(appdf.PRIVATE_SRC .. "plaza.src.models.PrivateFrame")

function RoomRecordLayer:ctor(wKindID)

    self._wKindID = wKindID

    --初始化变量
    self._btnTabs = {}
    self._listHeaders = {}
    self._recordTableViews = {}
    self._recordLists = {}
    self._selectedTab = 1

    --网络处理
    self._privateFrame = PrivateFrame:create(self, wKindID, function(result, message)
        self:onPrivateFrameCallBack(result, message)
    end)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Room/PrivateMode/RoomRecordLayer.csb"):addTo(self)
    local content = csbNode:getChildByName("content")

    content:getChildByName("btn_close"):addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --选项按钮
    for i = 1, 2 do
        local btnTab = content:getChildByName("btn_tab_" .. i)
        btnTab:addEventListener(function()
            self:onSelectTab(i)
        end)

        self._btnTabs[i] = btnTab
    end

    --活动指示器
    self._activity = ActivityIndicator:create()
    self._activity:setPosition(content:getContentSize().width / 2, content:getContentSize().height / 2)
    self._activity:addTo(content, 100)

    --tableview 回调
    local numberOfCellsInTableView = function(view)
        return self:numberOfCellsInTableView(view)
    end
    local cellSizeForTable = function(view, idx)
        return self:cellSizeForTable(view, idx)
    end
    local tableCellAtIndex = function(view, idx)	
        return self:tableCellAtIndex(view, idx)
    end
    local tableCellTouched = function(view, cell)
        return self:tableCellTouched(view, cell)
    end

    --列表
    for i = 1, 2 do

        --表头
        self._listHeaders[i] = content:getChildByName("sp_header_" .. i)

        local tableView = cc.TableView:create(cc.size(1158, 512))
        tableView:setTag(i)
	    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)    
        tableView:setAnchorPoint(cc.p(0, 0))
	    tableView:setPosition(cc.p(31, 35))
        tableView:setDelegate()
	    tableView:addTo(content)
	    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
        tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
        tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)

        tableView:reloadData()

        self._recordTableViews[i] = tableView
    end

    --选中第一个
    self:onSelectTab(1, false)

    --内容跳入
    AnimationHelper.jumpIn(content)
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

function RoomRecordLayer:onExit()
    
    if self._privateFrame:isSocketServer() then
        self._privateFrame:onCloseSocket()
    end
end

--切换选项卡
function RoomRecordLayer:onSelectTab(index, bSoundAble)

    if bSoundAble == nil or bSoundAble then
        --播放音效
        ExternalFun.playClickEffect()
    end

    self._selectedTab = index

    --设置选中状态
    for i = 1, #self._btnTabs do
        self._btnTabs[i]:setSelected(index == i)
        self._listHeaders[i]:setVisible(index == i)
        self._recordTableViews[i]:setVisible(index == i)
    end

    --关闭网络
    self._privateFrame:onCloseSocket()

    self._activity:start()

    if index == 1 then          --私人房列表
        
        self._privateFrame:onQueryRoomList()

    elseif index == 2 then      --参与列表

        self._privateFrame:onQueryJoinList()

    end
end

--------------------------------------------------------------------------------------------------------------------
-- TableView 数据源

--子视图数量
function RoomRecordLayer:numberOfCellsInTableView(view)
    
    local tag = view:getTag()

    if self._recordLists[tag] == nil then
        return 0
    end

    return #self._recordLists[tag]
end

--子视图大小
function RoomRecordLayer:cellSizeForTable(view, idx)

    return 1158, 66
end

--获取子视图
function RoomRecordLayer:tableCellAtIndex(view, idx)	
    
    --修正下标
    idx = idx + 1

    local tag = view:getTag()
    local columns = { 6, 5 }

    local cell = view:dequeueCell()
    if nil == cell then

        cell = cc.TableViewCell:create()

        local btnCell = ccui.Button:create("Room/PrivateMode/Record/sp_cell_normal.png", "Room/PrivateMode/Record/sp_cell_selected.png")
        btnCell:setAnchorPoint(cc.p(0, 0))
        btnCell:setSwallowTouches(false)
        btnCell:addTo(cell)

        local widths = { 
            { 248, 100, 112, 130, 248, 150 },
            { 248, 100, 258, 164, 248 }
        }
        local posXs = { 
            { 142, 342, 474, 612, 834, 1060 },
            { 142, 342, 548, 778, 1012 }
        }
        local contents = {
            { "2017/06/08 12:32:45", "123456", "5", "1房卡", "2017/06/08 12:32:45", "已解散" },
            { "2017/06/08 12:32:45", "123456", "tommy", "-500", "2017/06/08 12:32:45" }
        }

        for i = 1, columns[tag] do
            
            local txtColumn = ccui.Text:create(contents[tag][i], "fonts/round_body.ttf", 24)
            txtColumn:setTag(i)
            txtColumn:setPosition(posXs[tag][i], 33)
            txtColumn:setContentSize(widths[tag][i], 24)
            txtColumn:setColor(cc.c3b(98, 96, 91))
            txtColumn:addTo(cell)
        end
    end

    local item = self._recordLists[tag][idx]
    local contents = nil
    if tag == 1 then
        contents = { os.date("%Y/%m/%d %H:%M:%S", item.createTimeStamp), item.szRoomID, item.dwPlayTurnCount, item.lFeeCardOrBeanCount .. "房卡", item.cbIsDisssumRoom == 1 and os.date("%Y/%m/%d %H:%M:%S", item.dissumeTimeStamp) or "", item.cbIsDisssumRoom == 1 and "已解散" or "游戏中" }
    elseif tag == 2 then
        contents = {}
    end

    for i = 1, columns[tag] do

        local txtColumn = cell:getChildByTag(i)
        txtColumn:setString(contents[i]) 

        if tag == 1 and i == columns[tag] then
            if item.cbIsDisssumRoom == 0 then
                txtColumn:setColor(cc.c3b(226, 84, 40))     --游戏中
            else
                txtColumn:setColor(cc.c3b(40, 132, 226))    --已解散
            end
        end
    end

    return cell
end

--子视图点击
function RoomRecordLayer:tableCellTouched(view, cell)
    
    --播放音效
    ExternalFun.playClickEffect()
end

------------------------------------------------------------------------------------------------------------
-- PrivateFrame 回调

function RoomRecordLayer:onPrivateFrameCallBack(result, message)

    self._activity:stop()

    if type(message) == "string" and message ~= "" then
        showToast(nil, message, 2)
    end
end

--获取到私人房列表
function RoomRecordLayer:onGetRoomList(roomList)

    self._activity:stop()

    --{szRoomID="387089" lScore=0 cbIsDisssumRoom=1 createTimeStamp=1497163161 dissumeTimeStamp=1497166771 cbCardOrBean=1 sysCreateTime={wMilliseconds=0 wYear=2017 wMinute=39 wDayOfWeek=1 wHour=14 wMonth=6 wSecond=21 wDay=11 } lTaxCount=0 lFeeCardOrBeanCount=1 sysDissumeTime={wMilliseconds=0 wYear=2017 wMinute=39 wDayOfWeek=1 wHour=15 wMonth=6 wSecond=31 wDay=11 } PersonalUserScoreInfo={[1]={[1]={dwUserID=0 lScore=0 szUserNicname="" lGrade=0 lTaxCount=0 }

    self._recordLists[1] = roomList
    self._recordTableViews[1]:reloadData()
end

--获取到参与列表
function RoomRecordLayer:onGetJoinRoomList(joinRoomList)

    self._activity:stop()

    self._recordLists[2] = roomList
    self._recordTableViews[2]:reloadData()
end

return RoomRecordLayer