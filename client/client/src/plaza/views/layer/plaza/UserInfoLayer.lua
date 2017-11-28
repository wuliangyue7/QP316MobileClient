--玩家信息
local UserInfoLayer = class("UserInfoLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local HeadSprite = appdf.req(appdf.EXTERNAL_SRC .. "HeadSprite")

function UserInfoLayer:ctor(userItem)

    local csbNode = ExternalFun.loadCSB("UserInfo/UserInfoLayer.csb"):addTo(self)
    local content = csbNode:getChildByName("content")

    content:getChildByName("btn_close"):addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --昵称
    local txtNickName = content:getChildByName("txt_nickname")
    txtNickName:setString(userItem.NickName or userItem.szNickName)

    --游戏币
    local txtGold = content:getChildByName("txt_gold")
    txtGold:setString(ExternalFun.numberThousands(tonumber(userItem.Score or userItem.lScore)))

    --游戏ID
    local txtGameID = content:getChildByName("txt_gameid")
    txtGameID:setString(userItem.GameID or userItem.dwGameID)

    --签名
    local txtUnderWrite = content:getChildByName("txt_underwrite")
    txtUnderWrite:setString(userItem.szSign or userItem.szUnderWrite or userItem.UnderWrite or "这个家伙很懒，什么都没留下")

    --头像
    local headSprite = HeadSprite:createClipHead({ wFaceID = userItem.FaceID or userItem.wFaceID }, 96, "sp_avatar_mask_96.png")
    headSprite:setPosition(690, 340)
    headSprite:addTo(content)

    --内容跳入
    AnimationHelper.jumpIn(content)
end

return UserInfoLayer