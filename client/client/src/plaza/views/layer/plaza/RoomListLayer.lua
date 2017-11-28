-- 房间列表
local RoomListLayer = class("RoomListLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local RoomCreateLayer = appdf.req(appdf.CLIENT_SRC.."privatemode.plaza.src.views.RoomCreateLayer")
local RoomJoinLayer = appdf.req(appdf.CLIENT_SRC.."privatemode.plaza.src.views.RoomJoinLayer")
local RoomRecordLayer = appdf.req(appdf.CLIENT_SRC.."privatemode.plaza.src.views.RoomRecordLayer")

function RoomListLayer:ctor(delegate)
    
    self._delegate = delegate

    --开启级联透明度
    self:setCascadeOpacityEnabled(true)

    --背景
    self._content = cc.Sprite:create("RoomList/sp_background.png")
    self._content:setPosition(display.center)
    self._content:addTo(self)

    --房间列表视图
    self._scrollView = ccui.ScrollView:create()
    self._scrollView:setDirection(ccui.ScrollViewDir.vertical)
    self._scrollView:setAnchorPoint(cc.p(0.5,0.5))
--    self._scrollView:setBackGroundColor(cc.RED)
--    self._scrollView:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
--    self._scrollView:setBackGroundColorOpacity(100)
    self._scrollView:setBounceEnabled(true)
    self._scrollView:setScrollBarEnabled(false)
    self._scrollView:setContentSize(cc.size(1210, 538))
    self._scrollView:setPosition(self:getContentSize().width / 2, self:getContentSize().height / 2 - 15)
    self._scrollView:setVisible(false)
    self._scrollView:addTo(self)

    --房间分类视图
    self._categoryView = ccui.Layout:create()
    self._categoryView:setAnchorPoint(cc.p(0.5,0.5))
--    self._categoryView:setBackGroundColor(cc.RED)
--    self._categoryView:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
--    self._categoryView:setBackGroundColorOpacity(100)
    self._categoryView:setContentSize(cc.size(1210, 538))
    self._categoryView:setPosition(self:getContentSize().width / 2, self:getContentSize().height / 2 - 15)
    self._categoryView:setCascadeOpacityEnabled(true)
    self._categoryView:setVisible(false)
    self._categoryView:addTo(self)

    self._touchListener = function(ref, type)
        --改变按钮点击颜色
        if type == ccui.TouchEventType.began then
            ref:setColor(cc.c3b(200, 200, 200))
        elseif type == ccui.TouchEventType.ended or ccui.TouchEventType.canceled then
            ref:setColor(cc.WHITE)
        end
    end

    --游戏币场
    self._btnGoldRoom = ccui.Button:create("RoomList/icon_gold_room.png", "RoomList/icon_gold_room.png")
    self._btnGoldRoom:addTouchEventListener(self._touchListener)
    self._btnGoldRoom:addClickEventListener(function() self:onClickGoldRoom() end)
    self._btnGoldRoom:addTo(self._categoryView)

    --创建房间
    self._btnCreateRoom = ccui.Button:create("RoomList/icon_create_room.png", "RoomList/icon_create_room.png")
    self._btnCreateRoom:addTouchEventListener(self._touchListener)
    self._btnCreateRoom:addClickEventListener(function() self:onClickCreateRoom() end)
    self._btnCreateRoom:addTo(self._categoryView)

    --加入房间
    self._btnJoinRoom = ccui.Button:create("RoomList/icon_join_room.png", "RoomList/icon_join_room.png")
    self._btnJoinRoom:addTouchEventListener(self._touchListener)
    self._btnJoinRoom:addClickEventListener(function() self:onClickJoinRoom() end)
    self._btnJoinRoom:addTo(self._categoryView)

    --我的房间
    self._btnMyRoom = ccui.Button:create("RoomList/icon_my_room.png", "RoomList/icon_my_room.png")
    self._btnMyRoom:setPosition(self._categoryView:getContentSize().width - 26, self._categoryView:getContentSize().height / 2)
    self._btnMyRoom:addTouchEventListener(self._touchListener)
    self._btnMyRoom:addClickEventListener(function() self:onClickMyRoom() end)
    self._btnMyRoom:addTo(self._categoryView)
end

------------------------------------------------------------------------------------------------------------
-- 公共接口

--显示房间分类
function RoomListLayer:showRoomCategory(wKindID)

    print("显示房间分类")

    --保存游戏类型
    self._kindID = wKindID

    --显示
    self._categoryView:setVisible(true)
    self._scrollView:setVisible(false)

    local centerX = self._categoryView:getContentSize().width / 2
    local centerY = self._categoryView:getContentSize().height / 2

    local normalRoomCount = GlobalUserItem.getNormalRoomCount(wKindID)
    if normalRoomCount > 0 then
        self._btnGoldRoom:setPosition(centerX - 360, centerY)
        self._btnCreateRoom:setPosition(centerX, centerY)
        self._btnJoinRoom:setPosition(centerX + 360, centerY)
    else
        self._btnCreateRoom:setPosition(centerX - 250, centerY)
        self._btnJoinRoom:setPosition(centerX + 250, centerY)
    end

    --是否显示游戏币场
    self._btnGoldRoom:setVisible(normalRoomCount > 0)
end

--显示房间列表
function RoomListLayer:showRoomList(wKindID)
    
    print("显示房间列表", wKindID)

    --保存游戏类型
    self._kindID = wKindID

    --清空子视图
    self._scrollView:removeAllChildren()

    --显示
    self._categoryView:setVisible(false)
    self._scrollView:setVisible(true)

    --获取房间列表
    local roomList = GlobalUserItem.roomlist[wKindID]
    local roomCount = roomList and #roomList or 0

    local marginX           =   48  --X边距
    local marginY           =   26  --Y边距
    local spaceX            =   34  --X间距
    local spaceY            =   12  --Y间距

    local colCount          =   3
    local roomLines         =   math.ceil( roomCount / colCount )
    local roomSize          =   cc.size(349, 237)
    local contentSize       =   self._scrollView:getContentSize()
    local containerWidth    =   contentSize.width
    local containerHeight   =   marginY * 2 + roomLines * roomSize.height + (roomLines - 1) * spaceY;

    --判断容器高度是否小于最小高度
    if containerHeight < contentSize.height then
        containerHeight = contentSize.height
    end

    --设置容器大小
    self._scrollView:setInnerContainerSize(cc.size(containerWidth, containerHeight))

    --创建房间
    for i = 0, roomCount - 1 do

        --房间信息
        local roomInfo = roomList[i + 1]
     
        local iconfile  =   string.format("RoomList/icon_room_%d.png", roomInfo.wServerLevel % 10)
        local row       =   math.floor( i / colCount )
        local col       =   i % colCount
        local x         =   (marginX + roomSize.width / 2 + col * (spaceX + roomSize.width))
        local y         =   containerHeight - (marginY + roomSize.height / 2 + row * (spaceY + roomSize.height))

        local btnRoom = ccui.Button:create(iconfile, iconfile, iconfile)
        btnRoom:setPosition(x, y)
        btnRoom:setCascadeOpacityEnabled(true)
        btnRoom:addTo(self._scrollView)
        btnRoom:addTouchEventListener(self._touchListener)
        btnRoom:addClickEventListener(function()
            
            self:onClickRoom(roomInfo.wServerID)
        end)

        --房间名称
        local nServerNameLen = string.len(roomInfo.szServerName)
        local txtServerName = ccui.Text:create(roomInfo.szServerName, "fonts/round_body.ttf", (nServerNameLen > 10) and 32 or 36)
                                       :setPosition(175, 180)
                                       :setTextColor(cc.WHITE)
                                       :enableOutline(cc.c4b(0,0,0,255), 1)
                                       :addTo(btnRoom)
        --底分
        local txtCellScore = ccui.Text:create(roomInfo.lCellScore, "fonts/round_body.ttf", 32)
                                       :setPosition(205, 120)
                                       :setTextColor(cc.WHITE)
                                       :addTo(btnRoom)
        --在线人数
        local dwTotalOnlineCount = roomInfo.dwOnLineCount + roomInfo.dwAndroidCount
        local fOnlineRatio = dwTotalOnlineCount / roomInfo.dwFullCount
        local strOnlineStatus = "流畅"
        if fOnlineRatio > 2 / 3 then
            strOnlineStatus = "繁忙"
        elseif fOnlineRatio > 1 / 3 then
            strOnlineStatus = "拥挤" 
        end
        local txtOnlineStatus = ccui.Text:create(strOnlineStatus, "fonts/round_body.ttf", 24)
                                       :setAnchorPoint(cc.p(0,0.5))
                                       :setPosition(90, 54)
                                       :setTextColor(cc.c4b(223, 223, 223, 153))
                                       :addTo(btnRoom)

        --进入限制
        local strEnterLimit = "无限制"
        if roomInfo.lEnterScore >= 10000 then
            strEnterLimit = roomInfo.lEnterScore / 10000 .. "万以上"
        elseif roomInfo.lEnterScore > 0 then
            strEnterLimit = roomInfo.lEnterScore .. "以上"
        end
        local txtEnterScore = ccui.Text:create(strEnterLimit, "fonts/round_body.ttf", 24)
                                       :setAnchorPoint(cc.p(0,0.5))
                                       :setPosition(208, 54)
                                       :setTextColor(cc.c4b(223, 223, 223, 153))
                                       :addTo(btnRoom)
    end

    --滚动的到前面
    self._scrollView:jumpToTop()
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击返回
function RoomListLayer:onKeyBack()
    
    local privateRoomCount = GlobalUserItem.getPrivateRoomCount(self._kindID)

    if self._scrollView:isVisible() then
        if privateRoomCount > 0 then --显示房间分类
            self._categoryView:setVisible(true)
            self._scrollView:setVisible(false)
            return false
        end
    end

    return true
end

--点击游戏币场
function RoomListLayer:onClickGoldRoom()

    --播放按钮音效
    ExternalFun.playClickEffect()

    self:showRoomList(self._kindID)
end

--点击创建房间
function RoomListLayer:onClickCreateRoom()

    --播放按钮音效
    ExternalFun.playClickEffect()

    showPopupLayer(RoomCreateLayer:create(self._kindID))
end

--点击加入房间
function RoomListLayer:onClickJoinRoom()

    --播放按钮音效
    ExternalFun.playClickEffect()

    showPopupLayer(RoomJoinLayer:create(self._kindID))
end

--点击我的房间
function RoomListLayer:onClickMyRoom()

    --播放按钮音效
    ExternalFun.playClickEffect()

    showPopupLayer(RoomRecordLayer:create(self._kindID))
end

--点击房间
function RoomListLayer:onClickRoom(wServerID)

    print("点击房间图标", wServerID)

    --播放按钮音效
    ExternalFun.playClickEffect()

    if self._delegate and self._delegate.onClickRoom then
        self._delegate:onClickRoom(wServerID, self._kindID)
    end
end

return RoomListLayer