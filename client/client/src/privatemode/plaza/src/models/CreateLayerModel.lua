--
-- Author: zhong
-- Date: 2016-12-31 09:41:59
--
local CreateLayerModel = class("CreateLayerModel", ccui.Layout)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd_private = appdf.req(appdf.CLIENT_SRC .. "privatemode.header.CMD_Private")

function CreateLayerModel:ctor(scene)
    ExternalFun.registerNodeEvent(self)
    self._scene = scene
    self._cmd_pri_login = cmd_private.login
    self._cmd_pri_game = cmd_private.game
end

-- 刷新界面
function CreateLayerModel:onRefreshInfo()
    print("base refresh")
end

-- 获取邀请分享内容
function CreateLayerModel:getInviteShareMsg( roomDetailInfo )
    print("base get invite")
    return {title = "", content = ""}
end

------
-- 网络消息
------
-- 私人房创建成功
function CreateLayerModel:onRoomCreateSuccess()
    -- 创建成功
    if 0 == PriRoom:getInstance().m_tabRoomOption.cbIsJoinGame then
        -- 非必须加入
        PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_CREATERESULT, nil, self._scene)
    end
    self:onRefreshInfo()
end

-- 私人房登陆完成
function CreateLayerModel:onLoginPriRoomFinish()
    print("base login finish")
    return false
end

---------------------------------------------------------------------------------------------------------
--界面接口

--[LUA-print] - "<var>" = {
--[LUA-print] -     "cbCardOrBean"          = 1
--[LUA-print] -     "cbIsJoinGame"          = 0
--[LUA-print] -     "cbMaxPeople"           = 0
--[LUA-print] -     "cbMinPeople"           = 0
--[LUA-print] -     "dwPlayTimeLimit"       = 0
--[LUA-print] -     "dwPlayTurnCount"       = 0
--[LUA-print] -     "dwTimeAfterBeginCount" = 0
--[LUA-print] -     "dwTimeAfterCreateRoom" = 0
--[LUA-print] -     "dwTimeNotBeginGame"    = 0
--[LUA-print] -     "dwTimeOffLineCount"    = 0
--[LUA-print] -     "lFeeCardOrBeanCount"   = 0
--[LUA-print] -     "lIniScore"             = 0
--[LUA-print] -     "lMaxCellScore"         = 0
--[LUA-print] -     "wCanCreateCount"       = 5
--[LUA-print] - }

--[LUA-print] - "<var>" = {
--[LUA-print] -     1 = {
--[LUA-print] -         "dwDrawCountLimit" = 5
--[LUA-print] -         "dwDrawTimeLimit"  = 0
--[LUA-print] -         "lFeeScore"        = 1
--[LUA-print] -         "lIniScore"        = 1000
--[LUA-print] -     }
--[LUA-print] -     2 = {
--[LUA-print] -         "dwDrawCountLimit" = 10
--[LUA-print] -         "dwDrawTimeLimit"  = 0
--[LUA-print] -         "lFeeScore"        = 2
--[LUA-print] -         "lIniScore"        = 1000
--[LUA-print] -     }
--[LUA-print] - }

--创建详细参数视图
function CreateLayerModel:createDetailParamView(roomParam, roomFeeParam, detailParams)

    --设置背景颜色
--    self:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
--    self:setBackGroundColor(cc.c3b(100, 100, 100))
--    self:setBackGroundColorOpacity(255)

    --保存参数
    self._roomParam = roomParam
    self._roomFeeParam = roomFeeParam
    self._detailParams = detailParams

    --计算高度
    self._height = 0
    for i = 1, #detailParams do
        self._height = self._height + (detailParams[i].height or 0)
    end

    self:setContentSize(appdf.WIDTH, self._height)

    local yOffset = 40
    local check_0 = "Room/PrivateMode/Create/check_1_0.png"
    local check_1 = "Room/PrivateMode/Create/check_1_1.png"
    local normalColor = cc.c3b(120, 90, 75)
    local selectedColor = cc.c3b(226, 84, 40)

    for i = 1, #detailParams do
        
        local param = detailParams[i]

        --参数名称
        local txtName = ccui.Text:create(param.name .. "：", "fonts/round_body.ttf", 26)
        txtName:setColor(normalColor)
        txtName:setPosition(100, self._height - yOffset)
        txtName:addTo(self)

        --参数选项
        local options = param.options
        for j = 1, options and #options or 0 do
            
            local option = param.options[j]

            local row = math.floor((j - 1) / 4)
            local column = (j - 1) % 4
            local x = 180 + column * 200
            local y = yOffset + row * 68

            --点击事件
            local checkListener = function(ref)
                
                for k = 1, #options do
                    
                    local option = options[k]
                    local isChecked = (ref == option.checkCtrl)

                    --更新选项状态
                    if option.checkCtrl then
                        option.checkCtrl:setSelected(isChecked)
                    end

                    --更新选项颜色
                    if option.nameCtrl then
                        option.nameCtrl:setColor(isChecked and selectedColor or normalColor)
                    end

                    --更新房间费用
                    if option.fee and isChecked and self._txtFee then
                        self._txtFee:setString(option.fee .. (self._roomParam.cbCardOrBean == 1 and "房卡" or "游戏豆"))
                    end
                end
            end

            --选项状态
            local checkOption = ccui.CheckBox:create(check_0, check_0, check_1, check_0, check_1)
            checkOption:setAnchorPoint(0, 0.5)
            checkOption:setPosition(x, self._height - y)
            checkOption:addTo(self)
            checkOption:addEventListener(checkListener)

            --选项文本
            local txtOption = ccui.Text:create(option.name, "fonts/round_body.ttf", 26)
            txtOption:setAnchorPoint(0, 0.5)
            txtOption:setColor(normalColor)
            txtOption:setPosition(x + 52, self._height - y)
            txtOption:addTo(self)

            --保存控件
            option.checkCtrl = checkOption
            option.nameCtrl = txtOption

            --默认选中第一个
            if j == 1 then
                checkListener(checkOption)
            end
        end

        yOffset = yOffset + (param.height or 0)
    end

    --费用
    self._txtFee = ccui.Text:create("1房卡", "fonts/round_body.ttf", 26)
    self._txtFee:setAnchorPoint(0, 0.5)
    self._txtFee:setColor(selectedColor)
    self._txtFee:setPosition(190, self._height - yOffset)
    self._txtFee:addTo(self)
end

---------------------------------------------------------------------------------------------------------
--数据接口

--获取创建桌子数据
function CreateLayerModel:getCreateTableData()

    return nil
end

--获取房间详细参数值数组
function CreateLayerModel:getDetailParamValueArray(paramIndex)

    local values = {}
    local options = self._detailParams[paramIndex].options

    for i = 1, #options do
        local option = options[i]
        local checkCtrl = option.checkCtrl

        if checkCtrl:isSelected() then
            table.insert(values, option.value)
        end
    end

    return values
end

--获取房间详细参数值
function CreateLayerModel:getDetailParamValue(paramIndex)

    local options = self._detailParams[paramIndex].options

    for i = 1, #options do
        local option = options[i]
        local checkCtrl = option.checkCtrl

        if checkCtrl:isSelected() then
            return option.value
        end
    end

    return nil
end

--检查数据有效性
function CreateLayerModel:checkDetailParamValues()

    return nil
end

return CreateLayerModel