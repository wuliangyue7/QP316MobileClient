-- 导航管理器

local NavigationManager = class("NavigationManager")

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function NavigationManager:ctor(scene)
    
    self._scene = scene
end

function NavigationManager:push()

end

return NavigationManager