--修改头像页面
local ModifyAvatarLayer = class("ModifyAvatarLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")

function ModifyAvatarLayer:ctor()

    --网络处理
	self._modifyFrame = ModifyFrame:create(self, function(result,message)
        self:onModifyCallBack(result,message)
    end)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Modify/ModifyAvatarLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")
    self._scrollView = self._content:getChildByName("scrollview")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --加载头像
    self:onLoadAvatars()

    -- 内容跳入
    AnimationHelper.jumpIn(self._content)
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

function ModifyAvatarLayer:onExit()

    --关闭连接
    if self._modifyFrame:isSocketServer() then
        self._modifyFrame:onCloseSocket()
    end
end

--加载头像
function ModifyAvatarLayer:onLoadAvatars()

    local contentSize       =   self._scrollView:getContentSize()
    local faceCX            =   120
    local faceCY            =   120
    local spacing           =   9
    local columns           =   8
    local lines             =   math.ceil( yl.FACE_COUNT / columns )
    local containerWidth    =   contentSize.width
    local containerHeight   =   lines * faceCY + (lines - 1) * spacing;

    --判断容器高度是否小于最小高度
    if containerHeight < contentSize.height then
        containerHeight = contentSize.height
    end

    --设置容器大小
    self._scrollView:setInnerContainerSize(cc.size(containerWidth, containerHeight))

    for i = 0, yl.FACE_COUNT - 1 do
        
        local row       =   math.floor( i / columns )
        local col       =   i % columns
        local x         =   col * spacing + (col + 0.5) * faceCX
        local y         =   containerHeight - (row * spacing + (row + 0.5) * faceCY)

        --创建头像
        local avatar    =   ccui.Button:create("Avatar"..i..".png", "", "", ccui.TextureResType.plistType)
        avatar:setPosition(x, y)
             :setTag(i)
             :addTo(self._scrollView)
             :addClickEventListener(function()

                --播放音效
                ExternalFun.playClickEffect()

                --修改头像
                showPopWait()

                self._modifyFrame:onModifySystemHead(i)
             end)
    end
end

--------------------------------------------------------------------------------------------------------------------
-- ModifyFrame 回调

--操作结果
function ModifyAvatarLayer:onModifyCallBack(result,message)

    dismissPopWait()

	if message ~= nil and message ~= "" then
		showToast(nil,message,2)
	end

    --修改头像成功
    if yl.SUB_GP_USER_FACE_INFO == result then

        --通知更新头像
	    local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
        eventListener.obj = yl.RY_MSG_USERHEAD
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)

        dismissPopupLayer(self)
    end
end

return ModifyAvatarLayer