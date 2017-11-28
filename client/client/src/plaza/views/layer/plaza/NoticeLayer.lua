--游戏公告
local NoticeLayer = class("NoticeLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local ActivityIndicator = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.general.ActivityIndicator")

local ZORDER = 
{
    WEBVIEW = 10,
    ACTIVITY = 10000,
}

function NoticeLayer:ctor()

    --默认选中项
    self._selectIndex = 0

    --初始列表
    self._list = {}

    local csbNode = ExternalFun.loadCSB("Notice/NoticeLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

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

    --公告列表
	self._tableView = cc.TableView:create(cc.size(274, 514))
	self._tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)    
    self._tableView:setAnchorPoint(cc.p(0, 0))
	self._tableView:setPosition(cc.p(26, 48))
	self._tableView:setDelegate()
	self._tableView:addTo(self._content)
	self._tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	self._tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	self._tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
    self._tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)
    
    --活动指示器
    self._activity = ActivityIndicator:create()
    self._activity:setPosition(self._content:getContentSize().width / 2, self._content:getContentSize().height / 2)
    self._activity:addTo(self._content, ZORDER.ACTIVITY)

    --平台判定
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then

        --网页
        self._webView = ccexp.WebView:create()
        self._webView:setPosition(696, 305)
        self._webView:setContentSize(770, 510)
        self._webView:setScalesPageToFit(false) 
        --self._webView:loadURL("http://www.baidu.com")
        self._webView:addTo(self._content, ZORDER.WEBVIEW)
        
        self._webView:setOnShouldStartLoading(function(sender, url)
            
            --print("WebView_onShouldStartLoading, url is ", url)
            self._activity:start()

            --隐藏网页
            ExternalFun.visibleWebView(self._webView, false)
                   
            return true
        end)
        self._webView:setOnDidFailLoading(function ( sender, url )

            print("WebView_onDidFailLoading, url is ", url) 
            self._activity:stop()

            return true
        end)
        self._webView:setOnDidFinishLoading(function(sender, url)

            print("WebView_onDidFinishLoading, url is ", url)
            self._activity:stop()

            --显示网页
            ExternalFun.visibleWebView(self._webView, true)

            return true
        end)

        --网页初始化不显示
        ExternalFun.visibleWebView(self._webView, false)
    end

    --内容跳出
    AnimationHelper.jumpIn(self._content)

    --请求公告列表
    self:requestNoticeList()
end

--加载公告页面
function NoticeLayer:loadNoticeView(index)

    if self._webView then

        local notice = self._list[index]

        if notice then
            self._webView:stopLoading()
            self._webView:loadURL(yl.HTTP_URL .. "/News/NoticeView.aspx?param=" .. notice["NewsID"])
        end
    end
end

--------------------------------------------------------------------------------------------------------------------
-- TableView 数据源

--子视图数量
function NoticeLayer:numberOfCellsInTableView(view)
    
    return #self._list 
end

--子视图大小
function NoticeLayer:cellSizeForTable(view, idx)

    return 274, 96
end

--获取子视图
function NoticeLayer:tableCellAtIndex(view, idx)	
    
    local cell = view:dequeueCell()
    if nil == cell then

        cell = cc.TableViewCell:create()

        --背景
        cc.Sprite:create()
            :setAnchorPoint(0, 0)
            :setPosition(0, 0)
            :setTag(1)
            :addTo(cell)
        
        --类型
        ccui.Text:create("【公告】", "fonts/round_body.ttf", 24)
            :setColor(cc.c3b(240, 79, 0))
            :setPosition(130, 70)
            :setTag(2)
            :addTo(cell)

        --标题
        ccui.Text:create("", "fonts/round_body.ttf", 20)
            :setColor(cc.c3b(158, 64, 18))
            :setPosition(132, 35)
            :setTag(3)
            :addTo(cell)
    end

    cell.tag = idx

    local notice = self._list[idx + 1]

    --背景
    local bg = cell:getChildByTag(1)
    bg:setTexture(idx == self._selectIndex and "Notice/sp_item_bg_1.png" or "Notice/sp_item_bg_0.png")

        --标题
    local title = cell:getChildByTag(2)
    title:setString(notice.Subject)
	--时间
    local IssueDate = cell:getChildByTag(3)
    IssueDate:setString(notice.IssueDate)
    return cell
end

--子视图点击
function NoticeLayer:tableCellTouched(view, cell)
    
    local oldSelectIndex = self._selectIndex
    local index = cell.tag 

    if oldSelectIndex ~= index then

        self._selectIndex = index

        view:updateCellAtIndex(oldSelectIndex)
        view:updateCellAtIndex(index)

        --播放音效
        ExternalFun.playClickEffect()

        --加载页面
        self:loadNoticeView(index + 1)
    end
end

--------------------------------------------------------------------------------------------------------------------
-- 网络请求

--获取公告列表
function NoticeLayer:requestNoticeList()
    
	local url = yl.HTTP_URL .. "/ws/MobileInterface.ashx"
 	appdf.onHttpJsionTable(url ,"GET","action=getmobilenoticenew",function(jstable,jsdata)
        
        --对象已经销毁
		if not appdf.isObject(self) then
            return
        end

        --停止转圈
        self._activity:stop()

        --数据校验
        if type(jstable) ~= "table" or jstable["total"] == nil then
            return
        end

        local list = jstable["list"]
        if type(list) ~= "table" or #list == 0 then
            return
        end

        --保存列表，加载第一页
        self._list = list
        self._tableView:reloadData()
        self:loadNoticeView(1)
    end)
end

return NoticeLayer