--银行页面
local BankLayer = class("BankLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local ActivityIndicator = appdf.req(appdf.CLIENT_SRC .. "plaza.views.layer.general.ActivityIndicator")

local GameFrameEngine = appdf.req(appdf.CLIENT_SRC.."plaza.models.GameFrameEngine")
local BankFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BankFrame")

local TransferCertificateLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.TransferCertificateLayer")

--分类
local Categorys = 
{
    Take = 1,
    Save = 2,
    Transfer = 3,
    RecordIn = 4,
    RecordOut = 5,
    Count = 5
}

--转账类型
local TransferType = 
{
    In = 1,
    Out = 2
}

function BankLayer:ctor()
    
    --初始化分类按钮列表
    self._btnCategorys = {}
    --初始化分类面板列表
    self._panelCategorys = {}
    --转账记录
    self._recordLists = {}
    self._recordTableViews = {}

    --网络处理
	self._bankFrame = BankFrame:create(self,function(result,message)
        self:onBankCallBack(result,message)
    end)
    GameFrameEngine:getInstance():addShotFrame(self._bankFrame)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    --事件监听
    self:initEventListener()

    local csbNode = ExternalFun.loadCSB("Bank/BankLayer.csb"):addTo(self)
    self._top = csbNode:getChildByName("top")
    self._content = csbNode:getChildByName("content")
    self._txtGold = self._top:getChildByName("gold_info"):getChildByName("txt_gold")
    self._txtBank = self._top:getChildByName("bank_info"):getChildByName("txt_bank")

    --返回
    local btnBack = self._top:getChildByName("btn_back")
    btnBack:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        self:removeFromParent()
    end)

    --分类按钮
    for i = 1, Categorys.Count do

        local btnCategory = self._content:getChildByName("btn_category_" .. i)
        btnCategory:addEventListener(function()
            
            self:onClickCategory(i)
        end)

        --苹果审核隐藏掉
        if yl.APPSTORE_VERSION and i > 2 then
            btnCategory:setVisible(false)
        end

        self._btnCategorys[i] = btnCategory
    end

    --分类面板
    local panels = self._content:getChildByName("panels")
    for i = 1, Categorys.Count do

        self._panelCategorys[i] = panels:getChildByName(i)

        --初始化
        self:onInitCategoryPanel(i)
    end

    --更新分数
    self:onUpdateScoreInfo()

    --获取分数信息
    self._bankFrame:onGetBankInfo()
end

function BankLayer:onExit()
    
    --关闭网络
    if self._bankFrame:isSocketServer() then
        self._bankFrame:onCloseSocket()
    end
    GameFrameEngine:getInstance():removeShotFrame(self._bankFrame)
end

--初始化事件监听
function BankLayer:initEventListener()

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

    --用户信息改变事件
    eventDispatcher:addEventListenerWithSceneGraphPriority(
        cc.EventListenerCustom:create(yl.RY_USERINFO_NOTIFY, handler(self, self.onUserInfoChange)),
        self
        )
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

--用户信息改变
function BankLayer:onUserInfoChange(event)
    
    print("----------BankLayer:onUserInfoChange------------")

	local msgWhat = event.obj
	if nil ~= msgWhat and msgWhat == yl.RY_MSG_USERWEALTH then
		--更新财富
		self:onUpdateScoreInfo()
	end
end

--更新分数信息
function BankLayer:onUpdateScoreInfo()

   self._txtGold:setString(ExternalFun.numberThousands(GlobalUserItem.lUserScore))
   self._txtBank:setString(ExternalFun.numberThousands(GlobalUserItem.lUserInsure))
end

--初始化分类面板
function BankLayer:onInitCategoryPanel(index)

    local panel = self._panelCategorys[index]
    local spEditBg = nil

    if index == Categorys.Take then         --取款
        
        --取款数量
        spEditBg = panel:getChildByName("sp_edit_take_count_bg")
        self._editTakeCount = self:onCreateEditBox(spEditBg, false, true, 12)

        --银行密码
        spEditBg = panel:getChildByName("sp_edit_bank_pwd_bg")
        self._editTakePwd = self:onCreateEditBox(spEditBg, true, false, 18)
        self._editTakePwd:setText(GlobalUserItem.szInsurePass)

        --全部取出
        local btnAllTake = panel:getChildByName("btn_all_take")
        btnAllTake:addClickEventListener(function()
            self:onClickAllTake()
        end)

        --取出
        local btnTake = panel:getChildByName("btn_take")
        btnTake:addClickEventListener(function()
            self:onClickTake()
        end)

    elseif index == Categorys.Save then     --存款

        --存款数量
        spEditBg = panel:getChildByName("sp_edit_save_count_bg")
        self._editSaveCount = self:onCreateEditBox(spEditBg, false, true, 12)

        --全部存入
        local btnAllSave = panel:getChildByName("btn_all_save")
        btnAllSave:addClickEventListener(function()
            self:onClickAllSave()
        end)

        --存入
        local btnSave = panel:getChildByName("btn_save")
        btnSave:addClickEventListener(function()
            self:onClickSave()
        end)

    elseif index == Categorys.Transfer then --赠送

        --赠送ID
        spEditBg = panel:getChildByName("sp_edit_transfer_id_bg")
        self._editTransferID = self:onCreateEditBox(spEditBg, false, true, 8)

        --赠送数量
        spEditBg = panel:getChildByName("sp_edit_transfer_count_bg")
        self._editTransferCount = self:onCreateEditBox(spEditBg, false, true, 12)

        --银行密码
        spEditBg = panel:getChildByName("sp_edit_bank_pwd_bg")
        self._editTransferPwd = self:onCreateEditBox(spEditBg, true, false, 18)
        self._editTransferPwd:setText(GlobalUserItem.szInsurePass)

        --赠送
        local btnTransfer = panel:getChildByName("btn_transfer")
        btnTransfer:addClickEventListener(function()
            self:onClickTransfer()
        end)

    elseif index == Categorys.RecordIn or 
           index == Categorys.RecordOut then --转入、转出记录

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

        --转账列表
	    local tableView = cc.TableView:create(cc.size(960, 494))
	    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)    
        tableView:setAnchorPoint(cc.p(0, 0))
	    tableView:setPosition(cc.p(10, 10))
        tableView:setContentSize(960, 494)
	    tableView:setDelegate()
	    tableView:addTo(panel)
	    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
        tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
        tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)

        tableView:reloadData()

        --保存
        if index == Categorys.RecordIn then

            tableView:setTag(TransferType.In)
            self._recordTableViews[TransferType.In] = tableView
        elseif index == Categorys.RecordOut then

            tableView:setTag(TransferType.Out)
            self._recordTableViews[TransferType.Out] = tableView
        end
    end

end

--创建编辑框
function BankLayer:onCreateEditBox(spEditBg, isPassword, isNumeric, maxLength)
    
    local inputMode = isNumeric and cc.EDITBOX_INPUT_MODE_NUMERIC or cc.EDITBOX_INPUT_MODE_SINGLELINE

    local sizeBg = spEditBg:getContentSize()
    local editBox = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(30)
        :setFontColor(cc.WHITE)
		:setFontName("fonts/round_body.ttf")
		:setMaxLength(maxLength)
        :setInputMode(inputMode)
		:addTo(spEditBg) 

    --密码框
    if isPassword then
        editBox:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    end

    return editBox
end

--清空编辑框
function BankLayer:onClearEditBoxs()
    
    local editBoxs = {
        self._editTakeCount, self._editSaveCount, self._editTransferID, self._editTransferCount
    }

    for i = 1, #editBoxs do
        editBoxs[i]:setText("")
    end

    --读取密码
    if GlobalUserItem.szInsurePass ~= "" then
        self._editTakePwd:setText(GlobalUserItem.szInsurePass)
        self._editTransferPwd:setText(GlobalUserItem.szInsurePass)
    end
end

--点击分类按钮
function BankLayer:onClickCategory(index)

    --播放按钮音效
    ExternalFun.playClickEffect()

    for i = 1, Categorys.Count do
        self._btnCategorys[i]:setSelected(index == i)
        self._panelCategorys[i]:setVisible(index == i)
    end

    --清空文本框
    self:onClearEditBoxs()

    --获取转账记录
    if index == Categorys.RecordIn then
        self:requestBankRecord(TransferType.In)
    elseif index == Categorys.RecordOut then
        self:requestBankRecord(TransferType.Out)
    end
end

--点击全部取出
function BankLayer:onClickAllTake()
    
    --播放按钮音效
    ExternalFun.playClickEffect()

    self._editTakeCount:setText(GlobalUserItem.lUserInsure)
end

--点击取出
function BankLayer:onClickTake()
    
    --播放按钮音效
    ExternalFun.playClickEffect()

    --参数判断
	local szScore =  string.gsub(self._editTakeCount:getText(),"([^0-9])","")
    szScore = string.gsub(szScore, "[.]", "")
	local szPass = self._editTakePwd:getText()
    if #szScore < 1 then 
        showToast(self,"请输入取款数量！",2)
        return
    end

	local lOperateScore = tonumber(szScore)
	if lOperateScore < 1 then
		showToast(self,"请输入正确的取款数量！",2)
		return
	end

    if lOperateScore > GlobalUserItem.lUserInsure then
        showToast(self,"您银行游戏币的数目余额不足,请重新输入游戏币数量！",2)
        return
    end

	if #szPass < 1 then 
		showToast(self,"请输入银行密码！",2)
		return
	end
	if #szPass <6 then
		showToast(self,"密码必须大于6个字符，请重新输入！",2)
		return
	end

    --保存临时密码
    self._szTmpPass = szPass

	showPopWait()
	self._bankFrame:onTakeScore(lOperateScore,szPass)
end

--点击全部存入
function BankLayer:onClickAllSave()
    
    --播放按钮音效
    ExternalFun.playClickEffect()

    self._editSaveCount:setText(GlobalUserItem.lUserScore)
end

--点击存入
function BankLayer:onClickSave()
    
    --播放按钮音效
    ExternalFun.playClickEffect()

    	--参数判断
	local szScore =  string.gsub(self._editSaveCount:getText(),"([^0-9])","")	
    szScore = string.gsub(szScore, "[.]", "")
	if #szScore < 1 then 
		showToast(self,"请输入存款数量！",2)
		return
	end
	
	local lOperateScore = tonumber(szScore)
	
	if lOperateScore<1 then
		showToast(self,"请输入正确的存款数量！",2)
		return
	end

    if lOperateScore > GlobalUserItem.lUserScore then
        showToast(self,"您所携带游戏币的数目余额不足,请重新输入游戏币数量!",2)
        return
    end

	showPopWait()
	self._bankFrame:onSaveScore(lOperateScore)
end

--点击赠送
function BankLayer:onClickTransfer()
    
    --播放按钮音效
    ExternalFun.playClickEffect()

    --参数判断
	local szScore =  string.gsub(self._editTransferCount:getText(),"([^0-9])","")
	local szPass = self._editTransferPwd:getText()
	local szTarget = self._editTransferID:getText()
	local byID = 1--self.cbt_TransferByID:isSelected() and 1 or 0;

    if #szTarget < 1 then 
		showToast(self,"请输入赠送用户ID！",2)
		return
	end

	if #szScore < 1 then 
		showToast(self,"请输入赠送数量！",2)
		return
	end

	local lOperateScore = tonumber(szScore)
	if lOperateScore<1 then
		showToast(self,"请输入正确的数量！",2)
		return
	end

	if #szPass < 1 then 
		showToast(self,"请输入银行密码！",2)
		return
	end
	if #szPass <6 then
		showToast(self,"密码必须大于6个字符，请重新输入！",2)
		return
	end

    --保存临时密码
    self._szTmpPass = szPass

	showPopWait()
	self._bankFrame:onTransferScore(lOperateScore,szTarget,szPass,byID)
end

--------------------------------------------------------------------------------------------------------------------
-- TableView 数据源

--子视图数量
function BankLayer:numberOfCellsInTableView(view)
    
    local tag = view:getTag()

    if self._recordLists[tag] == nil then
        return 0
    end

    return #self._recordLists[tag]
end

--子视图大小
function BankLayer:cellSizeForTable(view, idx)

    return 960, 48
end

--获取子视图
function BankLayer:tableCellAtIndex(view, idx)	
    
    --修正下标
    idx = idx + 1

    local cell = view:dequeueCell()
    if nil == cell then

        cell = cc.TableViewCell:create()

        local widths = { 105, 246, 170, 208, 230 }
        local posXs = { 60, 230, 430, 610, 838 }

        for i = 1, 5 do
            
            local txtColumn = ccui.Text:create("", "fonts/round_body.ttf", 26)
            txtColumn:setTag(i)
            txtColumn:setPosition(posXs[i], 20)
            txtColumn:setContentSize(widths[i], 24)
            txtColumn:setColor(cc.c3b(98, 96, 91))
            txtColumn:addTo(cell)
        end
    end

    local tag = view:getTag()
    local item = self._recordLists[tag][idx]
    local contents = { item.RecordID, item.TransferNickName, item.TransferAccounts, math.abs(tonumber(item.SwapScore)), os.date("%Y/%m/%d %H:%M:%S", GlobalUserItem:getDateNumber(item.CollectDate) / 1000) }
    for i = 1, 5 do

        local txtColumn = cell:getChildByTag(i)
        txtColumn:setString(contents[i]) 
    end

    return cell
end

--子视图点击
function BankLayer:tableCellTouched(view, cell)
    
end

--------------------------------------------------------------------------------------------------------------------
-- BankFrame 事件处理

--操作结果
function BankLayer:onBankCallBack(result,message)

    dismissPopWait()

    if message ~= nil and message ~= "" then
		showToast(nil,message,2)
	end

    if result == 1 then

        if self._bankFrame._oprateCode == BankFrame.OP_TAKE_SCORE then
            
            --保存密码
            GlobalUserItem.szInsurePass = self._editTakePwd:getText()

        elseif self._bankFrame._oprateCode == BankFrame.OP_SEND_SCORE then

            --保存密码
            GlobalUserItem.szInsurePass = self._editTransferPwd:getText()

            local tabTarget = self._bankFrame._tabTarget
            local tt = os.date("*t", tabTarget.opTime)

            -- 转账凭证
            local info = {
                SourceNickName = GlobalUserItem.szNickName,
                SourceGameID = GlobalUserItem.dwGameID,
                TargetNickName = tabTarget.opTargetAcconts,
                TargetGameID = tabTarget.opTargetID,
                Score = tabTarget.opScore,
                ScoreCN = ExternalFun.numberTransiform(tabTarget.opScore),
                Date = string.format("%d.%02d.%02d-%02d:%02d:%02d", tt.year, tt.month, tt.day, tt.hour, tt.min, tt.sec),
                CerID = md5(tabTarget.opTime)
            }

            showPopupLayer(TransferCertificateLayer:create(info))
        end

        --清空文本框
        self:onClearEditBoxs()
    end
end

--------------------------------------------------------------------------------------------------------------------
-- 网络请求

--请求银行记录
function BankLayer:requestBankRecord(transfertype)

    showPopWait()

    local action = "action=getbankrecord&userid="..GlobalUserItem.dwUserID.."&signature="..GlobalUserItem:getSignature(os.time()).."&time="..os.time().."&number=50&page=1&transfertype="..transfertype
    appdf.onHttpJsionTable(yl.HTTP_URL .. "/WS/MobileInterface.ashx","GET", action, function(jstable,jsdata)
		
        dismissPopWait()

        --对象已经销毁
		if not appdf.isObject(self) then
            return
        end

		if jstable then
			local code = jstable["code"]
			if tonumber(code) == 0 then
				local datax = jstable["data"]
				if datax then
					local valid = datax["valid"]
					if valid == true then
						local listcount = datax["total"]
						local list = datax["list"]
						if type(list) == "table" then

                            --保存并刷新数据
                            self._recordLists[transfertype] = list
                            self._recordTableViews[transfertype]:reloadData()
						end
					end
				end
			end
		else
			showToast(nil,"抱歉，获取银行记录信息失败！",2)
		end
	end)
end

return BankLayer