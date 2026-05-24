local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt", nil, inst.hurtsoundvolume)
    end
end
AddStategraphPostInit("wilson", function(sg)
    --受击无硬直
    local eve1 = sg.events["attacked"]
    if eve1 then
        local event_fn_attacked = eve1.fn
        eve1.fn = function(inst, data, ...)
            if not inst.components.health:IsDead() and not inst.sg:HasStateTag("drowning") then
                if not inst.sg:HasStateTag("sleeping") then --睡袋貌似有自己的特殊机制
                    
                    if inst:HasTag("overlord") then
                    -- if inst.components.inventory:EquipHasTag("overlord") then
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                        DoHurtSound(inst)
                        return
                    end
                end
            end
            return event_fn_attacked(inst, data, ...)
        end
    end
end)