--游戏商城
local ShopLayer = class("ShopLayer", cc.Layer)

local QueryDialog = appdf.req(appdf.BASE_SRC .. "app.views.layer.other.QueryDialog")

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local ActivityIndicator = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.general.ActivityIndicator")
local PaymentLayer = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.plaza.PaymentLayer")
local CardPayLayer = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.plaza.CardPayLayer")

local ShopDetailFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ShopDetailFrame")
local RequestManager = appdf.req(appdf.CLIENT_SRC.."plaza.models.RequestManager")

local targetPlatform = cc.Application:getInstance():getTargetPlatform()

--列表类型
local ListType = 
{
    Bean = 1,
    Gold = 2,
    RoomCard = 3
}

--道具类型
local PropertyType =
{
    Gold = 5,
    RoomCard = 8
}

function ShopLayer:ctor(listType)

    --初始化分类按钮列表
    self._btnCategorys = {}
    --初始化列表类型
    self._listType = 0

    --网络处理
	self._shopDetailFrame = ShopDetailFrame:create(self, function(result, message)
        self:onShopDetailCallBack(result, message)
    end)

    --事件监听
    self:initEventListener()

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Shop/ShopLayer.csb"):addTo(self)
    self._top = csbNode:getChildByName("top")
    self._content = csbNode:getChildByName("content")
    self._txtBank = self._top:getChildByName("bank_info"):getChildByName("txt_bank")
    self._txtBean = self._top:getChildByName("bean_info"):getChildByName("txt_bean")
    self._txtRoomCard = self._top:getChildByName("roomcard_info"):getChildByName("txt_roomcard")

    --审核隐藏
    local txtDescription = self._content:getChildByName("txt_description")
    txtDescription:setVisible(not yl.APPSTORE_VERSION)

    self._top:getChildByName("roomcard_info"):setVisible(not yl.APPSTORE_VERSION)

    --返回
    local btnBack = self._top:getChildByName("btn_back")
    btnBack:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        self:removeFromParent()
    end)

    --分类按钮
    for i = 1, 3 do

        local btnCategory = self._content:getChildByName("btn_category_"..i)
        btnCategory:addEventListener(function(ref, type)
            
            self:onClickCategory(i, true)
        end)

        self._btnCategorys[i] = btnCategory

        if i == ListType.RoomCard then
            btnCategory:setVisible(not yl.APPSTORE_VERSION)
        end
    end

    --2017.8.13 暂时隐藏房卡商品
    self._btnCategorys[ListType.RoomCard]:setVisible(false)

    --充值卡兑换
    local btnCardPay = self._content:getChildByName("btn_card_pay")
    btnCardPay:setVisible(not yl.APPSTORE_VERSION)
    btnCardPay:addClickEventListener(function()
        
        self:onClickCardPay()
    end)

    --列表容器
    self._listContainer = self._content:getChildByName("list_container")
    self._listContainer:setScrollBarEnabled(false)

    --活动指示器
    self._activity = ActivityIndicator:create()
    self._activity:setPosition(yl.WIDTH / 2, yl.HEIGHT / 2)
    self._activity:stop()
    self._activity:addTo(self, 100)

    --更新分数信息
    self:onUpdateScoreInfo()

    --选中指定分类
    self:onClickCategory(listType or ListType.Bean)

    --刷新用户分数信息
    RequestManager.requestUserScoreInfo(nil)
end

--初始化事件监听
function ShopLayer:initEventListener()

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

    --用户信息改变事件
    eventDispatcher:addEventListenerWithSceneGraphPriority(
        cc.EventListenerCustom:create(yl.RY_USERINFO_NOTIFY, handler(self, self.onUserInfoChange)),
        self
        )
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

function ShopLayer:onExit()

    if self._shopDetailFrame:isSocketServer() then
        self._shopDetailFrame:onCloseSocket()
    end
end

--用户信息改变
function ShopLayer:onUserInfoChange(event)
    
    print("----------ShopLayer:onUserInfoChange------------")

	local msgWhat = event.obj
	if nil ~= msgWhat and msgWhat == yl.RY_MSG_USERWEALTH then
		--更新财富
		self:onUpdateScoreInfo()
	end
end

--更新分数信息
function ShopLayer:onUpdateScoreInfo()

   self._txtBank:setString(ExternalFun.numberThousands(GlobalUserItem.lUserInsure))
   self._txtBean:setString(ExternalFun.numberThousands(GlobalUserItem.dUserBeans))
   self._txtRoomCard:setString(ExternalFun.numberThousands(GlobalUserItem.lRoomCard))
end

--点击分类
function ShopLayer:onClickCategory(index, enableSound)

    --播放按钮音效
    if enableSound then
        ExternalFun.playClickEffect()
    end

    for i = 1, #self._btnCategorys do
        self._btnCategorys[i]:setSelected(index == i)
    end

    --防止重复执行
    if index == self._listType then
        return
    end

    self._listType = index

    
    --游戏豆
    if index == ListType.Bean then

        if GlobalUserItem.tabShopCache.shopBeanList == nil then
            self:requestBeanList()
            return
        end

    --游戏币
    elseif index == ListType.Gold then
        
        if GlobalUserItem.tabShopCache.shopGoldList == nil then
            self:requestPropertyList(PropertyType.Gold)
            return
        end

    --房卡
    elseif index == ListType.RoomCard then

        if GlobalUserItem.tabShopCache.shopRoomCardList == nil then
            self:requestPropertyList(PropertyType.RoomCard)
            return
        end

    end

    --更新列表
    self:updateList(index)
end

--点击充值卡兑换
function ShopLayer:onClickCardPay()

    --播放音效
    ExternalFun.playClickEffect()

    showPopupLayer(CardPayLayer:create())
end

--点击价格按钮
function ShopLayer:onClickPrice(listType, index, price, count, itemid, productid)

    print("点击价格按钮", listType, index)

    --播放音效
    ExternalFun.playClickEffect()

    if listType == ListType.Bean then

        --苹果支付
        if yl.APPSTORE_VERSION and (targetPlatform == cc.PLATFORM_OS_IPHONE or targetPlatform == cc.PLATFORM_OS_IPAD) then
            
            local payparam = {}
            payparam.http_url = yl.HTTP_URL
            payparam.uid = GlobalUserItem.dwUserID
            payparam.productid = productid
            payparam.price = price

            showPopWait()
            self:runAction(cc.Sequence:create(cc.DelayTime:create(5), cc.CallFunc:create(function()
                dismissPopWait()
            end)))
            showToast(nil, "正在连接iTunes Store...", 4)

            local function payCallBack(param)
                if type(param) == "string" and "true" == param then
  
                    showToast(nil, "支付成功", 2)

                    --刷新游戏豆列表
                    self:requestBeanList()

                    --刷新用户分数信息
                    RequestManager.requestUserScoreInfo(function(result, message)
            
                        if type(message) == "string" and message ~= "" then
                            showToast(nil,message,2)		
	                    end

                        if 0 == result then
                            --刷新当前列表
                            self:updateList(self._listType)
                        end
                    end)
                else
                    showToast(nil, "支付失败", 2)
                end
            end

            MultiPlatform:getInstance():thirdPartyPay(yl.ThirdParty.IAP, payparam, payCallBack)

        else

            --显示其他支付页面
            showPopupLayer(
                PaymentLayer:create(price, count, itemid, function(result)

                    if 0 == result then

                        --刷新游戏豆列表
                        self:requestBeanList()

                        --刷新用户分数信息
                        RequestManager.requestUserScoreInfo(function(result, message)
            
                            if type(message) == "string" and message ~= "" then
                                showToast(nil,message,2)		
	                        end

                            if 0 == result then
                                --刷新当前列表
                                self:updateList(self._listType)
                            end
                        end)
                    end
                end)
            )
        end

    elseif listType == ListType.Gold then
        
        --判断游戏豆是否足够
        if GlobalUserItem.dUserBeans == 0 or GlobalUserItem.dUserBeans < price then
            showToast(nil, "您的游戏豆不足，请先进行充值！", 2)
            return
        end

        --购买道具数量
        local propertyCount = (index == self:getListCount(listType) and price or 1)

        local callback = function(isOK)

            if isOK then
                showPopWait()

                --购买游戏币
                self._shopDetailFrame:onPropertyBuy(yl.CONSUME_TYPE_CASH, propertyCount, itemid, 0)
            end
        end

        QueryDialog:create("您要使用 " .. price .. " 游戏豆兑换 " .. count .. " 游戏币吗？", callback, nil, QueryDialog.QUERY_SURE_CANCEL)
            :addTo(self)
    elseif listType == ListType.RoomCard then
        
        --判断游戏豆是否足够
        if GlobalUserItem.dUserBeans == 0 or GlobalUserItem.dUserBeans < price then
            showToast(nil, "您的游戏豆不足，请先进行充值！", 2)
            return
        end

        --购买道具数量
        local propertyCount = price

        local callback = function(isOK)

            if isOK then
                showPopWait()

                --购买房卡
                self._shopDetailFrame:onPropertyBuy(yl.CONSUME_TYPE_CASH, propertyCount, itemid, 0)
            end
        end

        QueryDialog:create("您要使用 " .. price .. " 游戏豆兑换 " .. count .. " 房卡吗？", callback, nil, QueryDialog.QUERY_SURE_CANCEL)
            :addTo(self)
    end
end

------------------------------------------------------------------------------------------------------------
-- 界面操作

--获取列表数量
function ShopLayer:getListCount(listType)
    
    --游戏豆
    if listType == ListType.Bean then
        return GlobalUserItem.tabShopCache.shopBeanList and #GlobalUserItem.tabShopCache.shopBeanList or 0
    
    --游戏币
    elseif listType == ListType.Gold then
        return GlobalUserItem.tabShopCache.shopGoldList and #GlobalUserItem.tabShopCache.shopGoldList + 1 or 0
    
    --房卡
    elseif listType == ListType.RoomCard then
        return GlobalUserItem.tabShopCache.shopRoomCardList and 8 or 0
    end

    return 0
end

--获取列表
function ShopLayer:getListItem(listType, index)

    --图标数量
    local icon_counts = { 7, 7, 1 }
    --图标前缀
    local icon_prefixs = { "icon_bean_", "icon_gold_", "icon_roomcard_" }
    --热卖状态
    local hot_statuss = {
        { 0, 1, 0, 1, 0, 1, 1, 0 },
        { 1, 1, 0, 1, 1, 1, 0, 0 },
        { 0, 1, 1, 0, 0, 1, 0, 0 }
    }

    --商品数量
    local itemCount = 0
    local itemPrice = 0
    local itemId = 0
    local productId = ""
    local flagVisible = false
    local flagText = ""
    local flagFontSize = 27
    local giftVisible = false
    local giftText = ""
    local descriptionVisible = false
    local isHot = (hot_statuss[listType][index] == 1) --是否热卖

    --获取数据  
    if listType == ListType.Bean then               --游戏豆

        local itemInfo = GlobalUserItem.tabShopCache.shopBeanList[index]
        local isAttach = GlobalUserItem.bFirstPay and itemInfo.AttachCurrency > 0 --是否赠送

        itemCount = isAttach and itemInfo.PresentCurrency + itemInfo.AttachCurrency or itemInfo.PresentCurrency
        itemPrice = itemInfo.Price
        itemId = itemInfo.AppID
        productId = itemInfo.ProductID
        --flagVisible = isAttach or (not GlobalUserItem.bFirstPay and isHot)
        flagVisible = isAttach or isHot
        giftVisible = isAttach

        if isAttach then
            flagText = "首 充"
            giftText = "赠 2%"
        elseif isHot then
            flagText = "热 卖"
        end

    elseif listType == ListType.Gold then           --游戏币

        local itemInfo = nil

        --全部兑换
        if index == self:getListCount(listType) then
            itemInfo = GlobalUserItem.tabShopCache.shopGoldList[1]
            itemCount = GlobalUserItem.dUserBeans * itemInfo.BuyResultsGold --游戏豆数量乘以第一个等级兑换的游戏币数量
            itemPrice = GlobalUserItem.dUserBeans
            itemId = itemInfo.ID
            flagVisible = true
            flagText = "全部兑换"
            flagFontSize = 22
        else
            local itemInfo1 = GlobalUserItem.tabShopCache.shopGoldList[1]
            itemInfo = GlobalUserItem.tabShopCache.shopGoldList[index]
            itemCount = itemInfo.BuyResultsGold
            itemPrice = itemInfo.Cash
            itemId = itemInfo.ID
            flagVisible = isHot
            flagText = "热 卖"

            local originBuyResultGold = itemInfo1.BuyResultsGold * itemInfo.Cash
            local giftGold = itemInfo.BuyResultsGold - originBuyResultGold

            giftVisible = (giftGold > 0)
            if giftVisible then
                giftText = "赠 " .. (giftGold / originBuyResultGold * 100) .. "%"
            end
        end

    elseif listType == ListType.RoomCard then       --房卡

        local roomCardCounts = { 1, 5, 10, 50, 100, 200, 500, GlobalUserItem.dUserBeans }
        local itemInfo = GlobalUserItem.tabShopCache.shopRoomCardList[1] --以第一个配置为基础，后面的只是数量上的差别

        itemCount = itemInfo.Cash * roomCardCounts[index]
        itemPrice = itemInfo.Cash * roomCardCounts[index]
        itemId = itemInfo.ID

        --全部兑换
        if index == self:getListCount(listType) then
            flagVisible = true
            flagText = "全部兑换"
            flagFontSize = 22
        else
            flagVisible = isHot
            flagText = "热 卖"
        end
    else
        return nil
    end

    --背景
    local item = cc.Sprite:create("Shop/sp_item_bg.png")
    local itemSize = item:getContentSize()

    --商品图标
    local iconItem = cc.Sprite:create("Shop/icons/" .. icon_prefixs[listType] .. (index <= icon_counts[listType] and index or icon_counts[listType]) .. ".png")
    iconItem:setPosition(itemSize.width / 2, 180)
    iconItem:addTo(item)

    --商品数量
    local txtItemCount = cc.LabelAtlas:_create(itemCount, "Shop/sp_number_2.png", 22, 38, string.byte("0"))
    txtItemCount:setAnchorPoint(0.5, 0.5)
    txtItemCount:setPosition(itemSize.width / 2, 100)
    txtItemCount:addTo(item)

    --商品描述
    local txtItemDescription = ccui.Text:create("", "fonts/round_body.ttf", 18)
    txtItemDescription:setColor(cc.c3b(179, 151, 117))
    txtItemDescription:setPosition(itemSize.width / 2, 92)
    txtItemDescription:setVisible(descriptionVisible)
    txtItemDescription:addTo(item)

    --标签背景
    local flagBg = cc.Sprite:create("Shop/sp_flag_bg.png")
    flagBg:setPosition(56, 195)
    flagBg:setVisible(flagVisible)
    flagBg:addTo(item)

    --标签文本
    local txtFlag = ccui.Text:create(flagText, "fonts/round_body.ttf", flagFontSize)
    txtFlag:setPosition(42, 80)
    txtFlag:enableOutline(cc.c3b(208, 22, 21), 3)
    txtFlag:setRotation(-45)
    txtFlag:addTo(flagBg)

    --赠送背景
    local giftBg = cc.Sprite:create("Shop/sp_gift_bg.png")
    giftBg:setPosition(198, 236)
    giftBg:setVisible(giftVisible)
    giftBg:addTo(item)

    --赠送文本
    local txtGift = ccui.Text:create(giftText, "fonts/round_body.ttf", 22)
    txtGift:setPosition(54, 27)
    txtGift:enableOutline(cc.c3b(5, 110, 0), 1)
    txtGift:addTo(giftBg)

    --价格按钮
    local btnPrice = ccui.Button:create("Shop/btn_price_0.png", "Shop/btn_price_1.png")
    btnPrice:setPosition(itemSize.width / 2, 48)
    btnPrice:addTo(item)
    btnPrice:addClickEventListener(function()
        
        self:onClickPrice(listType, index, btnPrice._price, btnPrice._count, btnPrice._itemid, btnPrice._productid)
    end)
    btnPrice._price = itemPrice
    btnPrice._count = itemCount
    btnPrice._itemid = itemId
    btnPrice._productid = productId

    --价格按钮内容
    local txtPrice = ccui.Text:create(listType == ListType.Bean and "￥" .. itemPrice or itemPrice, "fonts/round_body.ttf", 36)
    txtPrice:setPosition(95, 35)
    txtPrice:enableOutline(cc.c3b(176, 71, 30), 2)
    txtPrice:addTo(btnPrice)

    --兑换类型显示游戏豆图标
    if listType ~= ListType.Bean then

        --价格按钮图标
        local iconPrice = cc.Sprite:create("Shop/icon_bean.png")
        iconPrice:addTo(btnPrice)

        local priceBtnWidth = btnPrice:getContentSize().width
        local priceTextWidth = txtPrice:getContentSize().width
        local priceIconWidth = iconPrice:getContentSize().width

        --调整位置
        local iconX = (priceBtnWidth - priceIconWidth - priceTextWidth - 4) / 2 + priceIconWidth / 2
        iconPrice:setPosition( iconX, 33 )
        txtPrice:setPosition( iconX + priceIconWidth / 2 + priceTextWidth / 2 + 4 , 35 )
    end

    return item
end

--更新列表 
function ShopLayer:updateList(listType)

    --非当前选择的列表，不更新
    if self._listType ~= listType then
        return
    end

    --清空列表
    self._listContainer:removeAllChildren()

    local marginX           =   8  --X边距
    local marginY           =   16  --Y边距
    local spaceX            =   3  --X间距
    local spaceY            =   14  --Y间距

    local listCount         =   self:getListCount(listType)
    local colCount          =   4
    local lineCount         =   math.ceil( listCount / colCount )
    local itemSize          =   cc.size(241, 258)
    local contentSize       =   self._listContainer:getContentSize()
    local containerWidth    =   contentSize.width
    local containerHeight   =   marginY * 2 + lineCount * itemSize.height + (lineCount - 1) * spaceY;

    --判断容器高度是否小于最小高度
    if containerHeight < contentSize.height then
        containerHeight = contentSize.height
    end

    --设置容器大小
    self._listContainer:setInnerContainerSize(cc.size(containerWidth, containerHeight))

    --创建列表
    for i = 0, listCount - 1 do

        local row       =   math.floor( i / colCount )
        local col       =   i % colCount
        local x         =   (marginX + itemSize.width / 2 + col * (spaceX + itemSize.width))
        local y         =   containerHeight - (marginY + itemSize.height / 2 + row * (spaceY + itemSize.height))

        local item      =   self:getListItem(listType, i + 1)
        item:setPosition(x, y)
        item:addTo(self._listContainer)
    end
end

------------------------------------------------------------------------------------------------------------
-- ShopDetailFrame 回调

function ShopLayer:onShopDetailCallBack(result, message)

    print("======== ShopLayer:onShopDetailCallBack ========")

    dismissPopWait()

    if type(message) == "string" and message ~= "" then
        showToast(nil,message,2)		
	end

    --道具购买成功
    if result == 1 then
        
        --刷新用户分数信息
        RequestManager.requestUserScoreInfo(function(result, message)
            
            if type(message) == "string" and message ~= "" then
                showToast(nil,message,2)		
	        end

            if 0 == result then
                --刷新当前列表
                self:updateList(self._listType)
            end
        end)
    end

    --需要返回道具是否自己使用，否则底层默认使用该道具
    return true
end

------------------------------------------------------------------------------------------------------------
-- 网络请求

--获取游戏豆列表
function ShopLayer:requestBeanList()

    self._activity:start()

    local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
    local ostime = os.time()
    appdf.onHttpJsionTable(url ,"GET","action=GetPayProduct&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime),function(jstable,jsdata)

        --对象已经销毁
        if not appdf.isObject(self) then
            return
        end

        self._activity:stop()

        if type(jstable) ~= "table" then
            return
        end

        local msg = jstable.msg
        if type(msg) == "string" then
           
            --弹出消息
        end

        local data = jstable.data 
        if type(data) ~= "table" then
            return
        end

        --是否首充
        GlobalUserItem.bFirstPay = not (data.IsPay == 1)

        local list = data.list
        if type(list) ~= "table" then
            return
        end

        --排序
        table.sort(list, function(a,b)
            return a.SortID < b.SortID
        end)

        --保存
        GlobalUserItem.tabShopCache.shopBeanList = list

        --更新游戏豆列表
        self:updateList(ListType.Bean)
    end)
end

--获取道具列表
function ShopLayer:requestPropertyList(typeID)

    self._activity:start()

    local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
    appdf.onHttpJsionTable(url, "GET", "action=GetMobileProperty&TypeID=" .. typeID,function(jstable,jsdata)

        --对象已经销毁
        if not appdf.isObject(self) then
            return
        end

        self._activity:stop()

        if type(jstable) ~= "table" then
            return
        end

        local msg = jstable.msg
        if type(msg) == "string" then
           
            --弹出消息
        end

        local data = jstable.data
        if type(data) ~= "table" or data.valid ~= true then
            return
        end

        local list = data.list
        if type(list) ~= "table" then
            return
        end

        --排序
        table.sort(list, function(a,b)
            return a.SortID < b.SortID
        end)

        if typeID == PropertyType.Gold then

            --保存
            GlobalUserItem.tabShopCache.shopGoldList = list
            --更新列表
            self:updateList(ListType.Gold)

        elseif typeID == PropertyType.RoomCard then
            
            --保存
            GlobalUserItem.tabShopCache.shopRoomCardList = list
            --更新列表
            self:updateList(ListType.RoomCard)

        end


    end)
end

return ShopLayer