--赠送凭证页面
local TransferCertificateLayer = class("TransferCertificateLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

function TransferCertificateLayer:ctor(info)

    local csbNode = ExternalFun.loadCSB("Bank/Certificate/TransferCertificateLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --填充内容
    local txtSourceNickName = self._content:getChildByName("txt_source_nickname")
    local txtSourceGameID = self._content:getChildByName("txt_source_gameid")
    local txtTargetNickName = self._content:getChildByName("txt_target_nickname")
    local txtTargetGameID = self._content:getChildByName("txt_target_gameid")
    local txtScore = self._content:getChildByName("txt_score")
    local txtScoreCN = self._content:getChildByName("txt_score_cn")
    local txtDate = self._content:getChildByName("txt_date")
    local txtCerID = self._content:getChildByName("txt_cer_id")

    txtSourceNickName:setString(info.SourceNickName)
    txtSourceGameID:setString(info.SourceGameID)
    txtTargetNickName:setString(info.TargetNickName)
    txtTargetGameID:setString(info.TargetGameID)
    txtScore:setString(info.Score)
    txtScoreCN:setString(info.ScoreCN)
    txtDate:setString(info.Date)
    txtCerID:setString(info.CerID)

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --分享
    local btnShare = self._content:getChildByName("btn_share")
    btnShare:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickShare()
    end)

    --保存
    local btnSave = self._content:getChildByName("btn_save")
    btnSave:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickSave()
    end)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content)
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击分享
function TransferCertificateLayer:onClickShare()

    local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
    local frameSize = cc.Director:getInstance():getOpenGLView():getFrameSize()
    local areaSize = self._content:getContentSize()
    local scaleX = frameSize.width / appdf.WIDTH
    local scaleY = frameSize.height / appdf.HEIGHT
    local area = cc.rect((appdf.WIDTH - frameSize.width) / 2 * scaleX, (appdf.HEIGHT - frameSize.height) / 2 * scaleY, frameSize.width * scaleX, frameSize.height * scaleY)

    ExternalFun.popupTouchFilter(0, false)

    captureScreenWithArea(area, "ce_code.png", function(ok, savepath)
        ExternalFun.dismissTouchFilter()
        if ok then
            MultiPlatform:getInstance():customShare(function(isok)
                        end, "转账凭证", "分享我的转账凭证", url, savepath, "true")
        end
    end)
end

--点击保存
function TransferCertificateLayer:onClickSave()

    local frameSize = cc.Director:getInstance():getOpenGLView():getFrameSize()
    local areaSize = self._content:getContentSize()
    local scaleX = frameSize.width / appdf.WIDTH
    local scaleY = frameSize.height / appdf.HEIGHT
    local area = cc.rect((appdf.WIDTH - frameSize.width) / 2 * scaleX, (appdf.HEIGHT - frameSize.height) / 2 * scaleY, frameSize.width * scaleX, frameSize.height * scaleY)

    ExternalFun.popupTouchFilter(0, false)

    captureScreenWithArea(area, "ce_code.png", function(ok, savepath)         
        ExternalFun.dismissTouchFilter()
        if ok then  
            if true == MultiPlatform:getInstance():saveImgToSystemGallery(savepath, os.time() .. "_ce_code.png") then
                showToast(nil, "您的转账凭证图片已保存至系统相册", 2)
            end
        end
    end)
end

return TransferCertificateLayer