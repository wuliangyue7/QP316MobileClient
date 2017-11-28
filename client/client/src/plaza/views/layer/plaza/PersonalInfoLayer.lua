--个人信息
local PersonalInfoLayer = class("PersonalInfoLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local HeadSprite = appdf.req(appdf.EXTERNAL_SRC .. "HeadSprite")

local BindingLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.BindingLayer")
local SpreadingLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.SpreadingLayer")
local MySpreaderLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.MySpreaderLayer")
local ShopLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ShopLayer")
local BankLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.BankLayer")
local BankEnableLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.BankEnableLayer")
local ModifyAvatarLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ModifyAvatarLayer")

local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")

function PersonalInfoLayer:ctor()

    --网络处理
	self._modifyFrame = ModifyFrame:create(self, function(result,message)
		self:onModifyCallBack(result,message)
	end)

    --事件监听
    self:initEventListener()

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("PersonalInfo/PersonalInfoLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --审核隐藏房卡
    if yl.APPSTORE_VERSION then

        local maskLayout = ccui.Layout:create()
        maskLayout:setContentSize(724, 78)
        maskLayout:setPosition(320, 200)
        maskLayout:setBackGroundColor(cc.c3b(255, 242, 223))
        maskLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        maskLayout:setTouchEnabled(true)
        maskLayout:addTo(self._content)
    end

    local editUnderwrite = self._content:getChildByName("edit_underwrite")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --头像按钮
    local btnAvatar = self._content:getChildByName("btn_avatar")
    btnAvatar:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        showPopupLayer(ModifyAvatarLayer:create(), false)
    end)

    --更换头像提示
    local posX, posY = btnAvatar:getPosition()
    cc.Sprite:create("PersonalInfo/sp_modify_avatar_tip.png")
        :setAnchorPoint(0.5, 0)
        :setPosition(posX, posY - 60)
        :addTo(self._content, 10)

    --性别
    self._checkMan = self._content:getChildByName("check_man")
    self._checkWoman = self._content:getChildByName("check_woman")
    self._checkMan:setSelected(GlobalUserItem.cbGender == 1)
    self._checkWoman:setSelected(GlobalUserItem.cbGender == 0)

    local checkClickFunc = function(ref)
        self:onClickSex(ref)
    end
    self._checkMan:addEventListener(checkClickFunc)
    self._checkWoman:addEventListener(checkClickFunc)

    --游戏ID
    local txtGameID = self._content:getChildByName("txt_gameid")
    txtGameID:setString(GlobalUserItem.dwGameID)

    --账号
    local txtAccount = self._content:getChildByName("txt_accounts")
    txtAccount:setString(GlobalUserItem.szAccount)

    --昵称
    local txtNickName = self._content:getChildByName("txt_nickname")
    txtNickName:setString(GlobalUserItem.szNickName)

    --游戏币
    local txtGold = self._content:getChildByName("txt_gold")
    txtGold:setString(ExternalFun.numberThousands(GlobalUserItem.lUserScore))

    --游戏豆
    local txtBean = self._content:getChildByName("txt_bean")
    txtBean:setString(ExternalFun.numberThousands(GlobalUserItem.dUserBeans))

    --房卡
    local txtRoomCard = self._content:getChildByName("txt_roomcard")
    txtRoomCard:setString(ExternalFun.numberThousands(GlobalUserItem.lRoomCard))

    --头像
    self:onUpdateUserFace()

    --个性签名输入框 
	self._editUnderwrite = ccui.EditBox:create(editUnderwrite:getContentSize(), "blank.png")
		:move(editUnderwrite:getPosition())
		:setAnchorPoint(cc.p(0, 1))
        :setFontSize(30)
        :setFontColor(cc.c3b(251, 238, 218))
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setPlaceholderFontSize(30)
        :setPlaceHolder("这个家伙很懒，什么都没留下")
        --:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setMaxLength(200)
        :setText(GlobalUserItem.szSign)
		:addTo(self._content)
        self._editUnderwrite:registerScriptEditBoxHandler(function(name, sender)
            self:onEditEvent(name, sender)
        end)
    editUnderwrite:removeFromParent()

    --复制ID
    local btnCopyID = self._content:getChildByName("btn_copyid")
    btnCopyID:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        MultiPlatform:getInstance():copyToClipboard("昵称："..GlobalUserItem.szNickName.."，ID："..GlobalUserItem.dwGameID)
        showToast(nil, "已复制到剪贴板", 2)
    end)

    --我的推广码
    local btnSpreading = self._content:getChildByName("btn_spreading")
    btnSpreading:setVisible(not yl.APPSTORE_VERSION)
    btnSpreading:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        showPopupLayer(SpreadingLayer:create(), false)
    end)

    --我的推荐人
    local btnMySpreader = self._content:getChildByName("btn_my_spreader")
    btnMySpreader:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        showPopupLayer(MySpreaderLayer:create(), false)
    end)

    --绑定
    local btnBinding = self._content:getChildByName("btn_binding")
    btnBinding:setVisible(GlobalUserItem.bVisitor)

    if GlobalUserItem.bVisitor then
        btnBinding:addClickEventListener(function()
            
            --播放音效
            ExternalFun.playClickEffect()

            showPopupLayer(BindingLayer:create(), false)
        end)
    end

    --取款
    local btnTake = self._content:getChildByName("btn_take")
    btnTake:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)

        local scene = cc.Director:getInstance():getRunningScene()
        if GlobalUserItem.cbInsureEnabled == 0 then
            showPopupLayer(BankEnableLayer:create(function()
                BankLayer:create():addTo(scene)
            end))
        else
            BankLayer:create():addTo(scene)
        end

    end)

    --充值游戏豆
    local btnRecharge = self._content:getChildByName("btn_recharge")
    btnRecharge:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)

        local scene = cc.Director:getInstance():getRunningScene()
        ShopLayer:create(1):addTo(scene)
    end)

   --购买房卡
    local btnBuy = self._content:getChildByName("btn_buy")
    btnBuy:setVisible(false) --2017.8.13 取消房卡购买
    btnBuy:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)

        local scene = cc.Director:getInstance():getRunningScene()
        ShopLayer:create(3):addTo(scene)
    end)

    --内容跳入
    AnimationHelper.jumpIn(self._content, function()
        
        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        self._editUnderwrite:setContentSize(self._editUnderwrite:getContentSize())
    end)
end

--初始化事件监听
function PersonalInfoLayer:initEventListener()

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

    --用户信息改变事件
    eventDispatcher:addEventListenerWithSceneGraphPriority(
        cc.EventListenerCustom:create(yl.RY_USERINFO_NOTIFY, handler(self, self.onUserInfoChange)),
        self
        )
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--用户信息改变
function PersonalInfoLayer:onUserInfoChange(event)
    
    print("----------PersonalInfoLayer:onUserInfoChange------------")

	local msgWhat = event.obj
	if nil ~= msgWhat then

        if msgWhat == yl.RY_MSG_USERWEALTH then
		    --更新财富
		    --self:onUpdateScoreInfo()
        elseif msgWhat == yl.RY_MSG_USERHEAD then
            --更新用户头像
            self:onUpdateUserFace()
        end
	end
end

--更新用户头像
function PersonalInfoLayer:onUpdateUserFace()
    
    local headSprite = self._content:getChildByName("sp_avatar")
    if headSprite then

        headSprite:updateHead(GlobalUserItem)
    else

        local btnAvatar = self._content:getChildByName("btn_avatar")

        headSprite = HeadSprite:createClipHead(GlobalUserItem, 120, "sp_avatar_mask_120.png")
        headSprite:setPosition(btnAvatar:getPosition())
        headSprite:addTo(self._content)
    end
end

function PersonalInfoLayer:onExit()

	if self._modifyFrame:isSocketServer() then
		self._modifyFrame:onCloseSocket()
	end
end

function PersonalInfoLayer:onEditEvent(name, sender)

    if name == "return" then

        --修改资料
        self:onSubmit()
    end
end

--点击性别
function PersonalInfoLayer:onClickSex(ref)

    --播放音效
    ExternalFun.playClickEffect()

    self._checkMan:setSelected(ref == self._checkMan)
    self._checkWoman:setSelected(ref == self._checkWoMan)

    self:onSubmit()
end

--提交信息
function PersonalInfoLayer:onSubmit()
    
    showPopWait()

    local cbGender = self._checkMan:isSelected() and yl.GENDER_MANKIND or yl.GENDER_FEMALE
    local szNickName = GlobalUserItem.szNickName
    local szSign = self._editUnderwrite:getText()

    self._modifyFrame:onModifyUserInfo(cbGender, szNickName, szSign)
end

--------------------------------------------------------------------------------------------------------------------
-- ModifyFrame 回调

--操作结果
function PersonalInfoLayer:onModifyCallBack(result,message)

    dismissPopWait()

	if  message ~= nil and message ~= "" then
		showToast(nil,message,2)
	end
	if -1 == result then
		return
	end

    local bGender = (GlobalUserItem.cbGender == yl.GENDER_MANKIND and true or false)
	self._checkMan:setSelected(bGender)
	self._checkWoman:setSelected(not bGender)
end

return PersonalInfoLayer