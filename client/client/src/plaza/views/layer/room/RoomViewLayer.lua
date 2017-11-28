--默认房间界面

local RoomViewLayer = class("RoomViewLayer", cc.Layer)

local HeadSprite = appdf.req(appdf.EXTERNAL_SRC .. "HeadSprite")

function RoomViewLayer:ctor(delegate)

    self._delegate = delegate

	--椅子位置定义 (以桌子背景为父节点得到的坐标)
	self.USER_POS = 
	{
		{cc.p(168,219)},	--1
		{cc.p(168,219),cc.p(168,-29)}, --2
		{cc.p(18,18),cc.p(170,222),cc.p(320,18)}, -- 3
		{cc.p(-18,109),cc.p(170,220),cc.p(360,109),cc.p(170,-27)}, -- 4
		{cc.p(-3,160),cc.p(170,220),cc.p(342,160),cc.p(310,6),cc.p(30,6)}, -- 5
		{cc.p(14,180),cc.p(170,220),cc.p(324,180),cc.p(324,19),cc.p(170,-26),cc.p(14,19)}, --6
		{cc.p(-20,100),cc.p(33,200),cc.p(170,220),cc.p(304,200),cc.p(360,100),cc.p(304,0),cc.p(33,0)}, --7
		{cc.p(-20,100),cc.p(33,200),cc.p(170,220),cc.p(304,200),cc.p(360,100),cc.p(304,0),cc.p(170,-26),cc.p(33,0)}, -- 8
		{cc.p(-18,72),cc.p(9,178),cc.p(107,220),cc.p(224,220),cc.p(326,178),cc.p(352,72),cc.p(282,-8),cc.p(167,-30),cc.p(51,-8)} --9
	}

    --桌子列表
    self._tableList = {}

    --滚动视图
    self._scrollView = ccui.ScrollView:create()
    self._scrollView:setDirection(ccui.ScrollViewDir.vertical)
    self._scrollView:setAnchorPoint(cc.p(0.5,0.5))
--    self._scrollView:setBackGroundColor(cc.RED)
--    self._scrollView:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
--    self._scrollView:setBackGroundColorOpacity(100)
    self._scrollView:setBounceEnabled(true)
    self._scrollView:setScrollBarEnabled(false)
    self._scrollView:setContentSize(cc.size(yl.WIDTH, 580))
    self._scrollView:setPosition(self:getContentSize().width / 2, self:getContentSize().height / 2 + 6)
    self._scrollView:addTo(self)
end

--创建桌子列表
function RoomViewLayer:createTableList(wTableCount, wChairCount)

    self._wTableCount = wTableCount
    self._wChairCount = wChairCount

    local contentSize       =   self._scrollView:getContentSize()
    local colCount          =   3
    local tableLines        =   math.ceil( wTableCount / colCount )
    local tableSize         =   cc.size(yl.WIDTH / colCount, contentSize.height / 1.5)
    local containerWidth    =   contentSize.width
    local containerHeight   =   tableLines * tableSize.height;

    --判断容器高度是否小于最小高度
    if containerHeight < contentSize.height then
        containerHeight = contentSize.height
    end

    --设置容器大小
    self._scrollView:setInnerContainerSize(cc.size(containerWidth, containerHeight))

    for i = 0, wTableCount - 1 do
        
        --创建桌子
        local table     =   self:createTable(i, wChairCount)

        local row       =   math.floor( i / colCount )
        local col       =   i % colCount
        local x         =   tableSize.width / 2 + col * tableSize.width
        local y         =   containerHeight - (tableSize.height / 2 + row * tableSize.height)

        table:setPosition(x, y)
             :setTag(i)
             :addTo(self._scrollView)

        --保存到列表
        self._tableList[#self._tableList + 1] = table

        --更新桌子状态
        self:updateTable(i)

        --更新椅子信息
        for j = 0, wChairCount - 1 do

            --玩家信息
            local userItem = self._delegate:getTableUserItem(i, j)

            if userItem ~= nil then
                self:updateChair(i, j, userItem)
            end
        end
    end
end

--创建桌子
function RoomViewLayer:createTable(wTableID, wChairCount)
    
    --创建桌子背景
    local table = self:createTableBg()
    local chair_pos = table.chair_pos

    --创建座位
    for i = 0, wChairCount - 1 do

        --座位按钮
        local btnChair = ccui.Button:create("Room/chair_empty.png", "Room/chair_empty.png")
        btnChair:setPosition(chair_pos[i + 1])
                :setTag(400 + i)
                :setSwallowTouches(false)
                :addTo(table, 400 + i)
                :addTouchEventListener(function(ref, type)

                    --改变按钮点击颜色
                    if type == ccui.TouchEventType.began then

                        ref:setColor(cc.c3b(200, 200, 200))
                        self._chairMoveCount = 0

                    elseif type == ccui.TouchEventType.moved then
                        
                        self._chairMoveCount = self._chairMoveCount + 1

                    elseif type == ccui.TouchEventType.ended then

                        ref:setColor(cc.WHITE)

                        --防止滑动的时候，按钮事件被触发
                        if self._chairMoveCount < 8 then
                            self:onSitDown(wTableID, i)
                        end

                    elseif type == ccui.TouchEventType.canceled then

                        ref:setColor(cc.WHITE)

                    end
                end)

        --设置桌号
        local txtTableID = table:getChildByTag(1)
        txtTableID:setString(string.format("%d号桌", wTableID + 1))
    end

    return table
end

--根据游戏类型、游戏人数区分桌子底图
function RoomViewLayer:createTableBg()
	local entergame = GlobalUserItem.tabEnterGame
	local sp_table = nil
	local chair_pos = nil

	--自定义资源
	local modulestr = string.gsub(entergame._KindName, "%.", "/")
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	local customRoomFile = ""
	if cc.PLATFORM_OS_WINDOWS == targetPlatform then
		customRoomFile = "game/" .. modulestr .. "src/views/GameRoomLayer.lua"
	else
		customRoomFile = "game/" .. modulestr .. "src/views/GameRoomLayer.luac"
	end
	if cc.FileUtils:getInstance():isFileExist(customRoomFile) then
        --print(package.path)
        local GameRoomLayer = appdf.req(customRoomFile)
        --showToast(nil, package.path, 10)
		sp_table, chair_pos = GameRoomLayer:getTableParam()
	end

	local bgSize = cc.size(0, 0)
	--默认资源
	if nil == sp_table or nil == chair_pos then
		print("RoomViewLayer:createTableBg default param")
		sp_table = cc.Sprite:create("Room/bg_table.png")
		chair_pos = self.USER_POS[self._wChairCount]

		bgSize = sp_table:getContentSize()
		--桌号背景
		display.newSprite("Room/bg_tablenum.png")
			:addTo(sp_table)
			:move(bgSize.width * 0.5,10)
		ccui.Text:create("", "fonts/round_body.ttf", 16)
			:addTo(sp_table)
			:setColor(cc.c4b(255,193,200,255))
			:setTag(1)
			:move(bgSize.width * 0.5,12)
		--状态
		display.newSprite("Room/flag_waitstatus.png")
			:addTo(sp_table)
			:setTag(2)
			:move(bgSize.width * 0.5, bgSize.height * 0.5)
	end
	bgSize = sp_table:getContentSize()
	--锁桌
	display.newSprite("Room/plazz_sp_locker.png")
		:addTo(sp_table)
		:setTag(3)
		:move(bgSize.width * 0.5, bgSize.height * 0.5)
	sp_table.chair_pos = chair_pos

	return sp_table
end

-- 更新桌子
function RoomViewLayer:updateTable(wTableID)

	local tableFile = ""
	local entergame = GlobalUserItem.tabEnterGame
	local modulestr = string.gsub(entergame._KindName, "%.", "/")

    --获取桌子信息
    local tableInfo = self._delegate:getTableInfo(wTableID + 1)
    local table = self._tableList[wTableID + 1]

    --桌子状态
	if 1 == tableInfo.cbPlayStatus then
		-- 游戏中
		tableFile = "game/" .. modulestr .. "res/roomlist/roomtable_play.png"

        table:getChildByTag(2):setTexture("Room/flag_playstatus.png")
	else 
		-- 等待中
		tableFile = "game/" .. modulestr .. "res/roomlist/roomtable.png"

        table:getChildByTag(2):setTexture("Room/flag_waitstatus.png")
	end
	
	if cc.FileUtils:getInstance():isFileExist(tableFile) then
		table:setTexture(tableFile)
	end

    --是否锁定
    table:getChildByTag(3):setVisible(1 == tableInfo.cbTableLock)
end

-- 更新椅子
function RoomViewLayer:updateChair(wTableID, wChairID, userItem)

    local chairTag = 400 + wChairID
    local avatarTag = 300 + wChairID
    local table = self._tableList[wTableID + 1]
    local chair = table:getChildByTag(chairTag)
    local chair_pos = table.chair_pos
    local avatar = table:getChildByTag(avatarTag)

    if userItem ~= nil then

        if avatar ~= nil then
            avatar:updateHead(userItem)
        else
            avatar = HeadSprite:createClipHead(userItem, 40)
                               :setTag(avatarTag)
                               :setPosition(chair_pos[wChairID + 1])
                               :addTo(table, avatarTag)
        end

        --显示头像
        avatar:setVisible(true)

        --切换按钮纹理
        chair:loadTextures("Room/bg_chair.png", "Room/bg_chair.png")
    else
        
        if avatar ~= nil then
            --隐藏头像
            avatar:setVisible(false)
        end

        --切换按钮纹理
        chair:loadTextures("Room/chair_empty.png", "Room/chair_empty.png")
    end
end

------------------------------------------------------------------------------------------------------------
-- 事件回调

--坐下
function RoomViewLayer:onSitDown(wTableID, wChairID)

    print("坐下:" .. wTableID .. "," .. wChairID)

    if self._delegate and self._delegate.onSitDown then
        self._delegate:onSitDown(wTableID, wChairID)
    end
end

return RoomViewLayer