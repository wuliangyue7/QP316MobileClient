--桌子密码页面
local TablePasswordLayer = class("TablePasswordLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")

function TablePasswordLayer:ctor(callback)

    local csbNode = ExternalFun.loadCSB("Room/TablePassword/TablePasswordLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")
    
    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --确定
    local btnOK = self._content:getChildByName("btn_ok")
    btnOK:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        local password = self._editPwd:getText()

        dismissPopupLayer(self)

        if callback then
            callback(password)
        end
    end)

    --编辑框
    local spEditBg = self._content:getChildByName("sp_edit_bg")
    local sizeBg = spEditBg:getContentSize()
    self._editPwd = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(30)
        :setFontColor(cc.WHITE)
		:setFontName("fonts/round_body.ttf")
		:setMaxLength(20)
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        --:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:addTo(spEditBg)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content, function()
        
        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        self._editPwd:setContentSize(self._editPwd:getContentSize())
    end)
end

return TablePasswordLayer