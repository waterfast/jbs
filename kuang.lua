local extension=Package("kuang")
extension.extensionName="jbs"

Fk:loadTranslationTable{
    ["kuang"]="狂",
    
}

local longqiang=General:new(extension,"longqiang","shu",3)
longqiang.shield=1

local longwei = fk.CreateTriggerSkill{
    name = "jbs__longwei",
    anim_type="drawcard",
    events = {fk.Damaged},
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
      return (target == player) and player:hasSkill(self.name) and not player.dead
    end,
    on_use = function(self, event, target, player, data)
      player:drawCards(1, self.name)
      player.room:addPlayerMark(player, "@jbs_long",1)
    end,
}

local longhun = fk.CreateTriggerSkill{
  name = "jbs__longhun",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and #player.player_cards[Player.Hand] < player:getMark("@jbs_long") then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          return move.from == player.id
        end
      else
        return target == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("@jbs_long")- #player.player_cards[Player.Hand], self.name)
  end,
}

longqiang:addSkill(longwei)
longqiang:addSkill(longhun)

Fk:loadTranslationTable{
    ["longqiang"] = "龙枪",
    ["jbs__longwei"]="龙威",
    [":jbs__longwei"]="当你受到一次伤害后，摸一张牌并获得一枚“龙”标记。",
    ["@jbs_long"] = "龙",
    ["jbs__longhun"]="龙魂",
    [":jbs__longhun"]="你的手牌数少于你“龙”的数目时，摸一张牌。",

}


local hakensa=General:new(extension,"hakensa","shu",4)

local yuhen = fk.CreateTriggerSkill{
  name = "jbs__yuhen",
  events = {fk.TurnStart},
  frequency = Skill.Compulsory,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@jbs_hen",player.room:getTag("RoundCount"))
  end,
}

local nuyan = fk.CreateActiveSkill{
  name = "jbs__nuyan",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:getMark("@jbs_hen") > 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getMark("@jbs_hen") > 2 then
      local choice = room:askForChoice(player, {"jbs_nuyan1", "jbs_nuyan2"}, self.name)
      if choice == "jbs_nuyan1" then
        player.room:removePlayerMark(player, "@jbs_hen", 1)
        player:drawCards(1, self.name)
      
      else 
        player.room:removePlayerMark(player, "@jbs_hen", 3)
        room:changeShield(player, 1)

      end
    else
      local choice = room:askForChoice(player, {"jbs_nuyan1"}, self.name)
      if choice == "jbs_nuyan1" then
        player.room:removePlayerMark(player, "@jbs_hen", 1)
        player:drawCards(1, self.name)
      end

    end


      
  end,

}


hakensa:addSkill(yuhen)
hakensa:addSkill(nuyan)

Fk:loadTranslationTable{
  ["hakensa"] = "哈肯萨",
  ["jbs__yuhen"]="余恨",
  [":jbs__yuhen"]="锁定技，每轮开始时，使你的“恨”标记的数目等于当前轮数。",
  ["@jbs_hen"] = "恨",
  ["jbs__nuyan"]="怒焰",
  [":jbs__nuyan"]="出牌阶段，你可以选择:1.弃置1个“恨”标记,摸一张牌;2.弃置3个“恨”标记,获得一点护甲",

  ["jbs_nuyan1"]="弃置1个“恨”标记,摸一张牌",
  ["jbs_nuyan2"]="弃置3个“恨”标记,获得一点护甲",
  


}

local xiuluozhihun=General:new(extension,"xiuluozhihun","wei",3)
xiuluozhihun.shield=1

local juling = fk.CreateTriggerSkill{
  name = "jbs__juling",
  events = {fk.HpChanged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player.dead
  end,

  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1)
    if player:isKongcheng() then return end
    local card = room:askForCard(player, 1, 1, false, self.name, false, ".", "#juling-card")
    local num=0
    for _, id in ipairs(card) do
      num = Fk:getCardById(id).number
    end
    player:addToPile("xiuluozhihun_hun", card, false, self.name)
    room:addPlayerMark(player, "@xiuluozhihun_hun",num)
    if player:getMark("@xiuluozhihun_hun") >= 28 then
        room:moveCards({
          from = player.id,
          ids = player:getPile("xiuluozhihun_hun"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        room:setPlayerMark(player, "@xiuluozhihun_hun",0)
        room:addPlayerMark(player, "@jbs_lingya",1)

    end

  end,
}

local lingya= fk.CreateViewAsSkill{
  name = "jbs__lingya",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and
        card.trueName ~= "nullification" and card.name ~= "adaptation" then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  anim_type = "special",
  expand_pile = "xiuluozhihun_hun",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return Self:getPileNameOfId(to_select) == "xiuluozhihun_hun"
    elseif #selected == 1 then 
      return Self:getPileNameOfId(to_select) == "xiuluozhihun_hun" and Fk:getCardById(to_select).suit == Fk:getCardById(selected[1]).suit
    elseif #selected == 2 then
      return false
    end

    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card

  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark("@jbs_lingya") and  #player:getPile("xiuluozhihun_hun") > 1
  end,
}

local lingya_cishu = fk.CreateTriggerSkill{
  name = "#jbs__lingya_cishu",
  mute = true,
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@jbs_lingya", 1)
  end,
}

local lingya_delay = fk.CreateTriggerSkill{
  name = "#jbs__lingya_delay",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player == target and table.contains(data.card.skillNames, lingya.name)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local num=0
    for _, id in ipairs(player:getPile("xiuluozhihun_hun")) do
      num = num+Fk:getCardById(id).number
    end
    player.room:setPlayerMark(player, "@xiuluozhihun_hun", num)
  end,
}

lingya:addRelatedSkill(lingya_cishu)
lingya:addRelatedSkill(lingya_delay)
xiuluozhihun:addSkill(juling)
xiuluozhihun:addSkill(lingya)

Fk:loadTranslationTable{
  ["xiuluozhihun"] = "修罗之魂",
  ["jbs__juling"]="聚灵",
  [":jbs__juling"]="锁定技，每当一名角色体力变化后，你摸一张牌并将一张手牌置于武将牌上，称做“魂”。你的“魂”总点数大于36时，你弃置所有“魂”并令[灵压]使用次数+1",
  ["jbs__lingya"]="灵压",
  [":jbs__lingya"]="出牌阶段限1次，你可以将两张花色相同的“魂”当一张任意非延时锦囊牌使用。",



  ["#juling-card"] = "聚灵：将一张手牌置为“魂”",
  ["@xiuluozhihun_hun"] = "魂点数",
  ["xiuluozhihun_hun"] = "魂",
  ["@jbs_lingya"] = "灵压次数",

}

local chen=General:new(extension,"jbs_chen","wei",4,4,General.Female)

local jianhao = fk.CreateTriggerSkill{
  name = "jbs__jianhao",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.is_damage_card
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jianhao = data.extra_data.jianhao or true
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.jianhao
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data.jianhao = false
    player.room:doCardUseEffect(data)
  end,
}

local badao = fk.CreateViewAsSkill{
  name = "jbs__badao",
  anim_type = "special",
  card_num = 0,
  view_as = function(self)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, useData)
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.os__kunsiUser = player.id
    useData.extraUse = true
    local targets = TargetGroup:getRealTargets(useData.tos)
    useData.extra_data.os__kunsiTarget = targets

  end,
  enabled_at_response = function(self, player, cardResponsing) return false end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) ==0 and not(player:getEquipment(Card.SubtypeWeapon) == nil)
  end,
}

local badao_buff = fk.CreateTargetModSkill{
  name = "#jbs__badao_buff",
  residue_func = function(self, player, skill, scope, card)
    return scope == Player.HistoryPhase and card and table.contains(card.skillNames, "jbs__badao") and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "jbs__badao") and 999 or 0
  end,
}

badao:addRelatedSkill(badao_buff)

chen:addSkill(jianhao)
chen:addSkill(badao)

Fk:loadTranslationTable{
  ["jbs_chen"] = "陈",
  ["jbs__jianhao"] = "剑豪",
  [":jbs__jianhao"] = "锁定技，你使用的伤害牌额外结算一次。",

  ["jbs__badao"] = "拔刀",
  [":jbs__badao"] = "出牌阶段限一次，如果你装备区里有武器牌，你可以视为使用一张无距离无次数限制的“杀”",

}

local erlangshen=General:new(extension,"jbs_erlangshen","wei",4,4)

--[[local xixue = fk.CreateTriggerSkill{
  name = "jbs_xixue",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if  player:isWounded() then
      room:recover({
        who = player,
        num = data.damage,
        recoverBy = player,
        skillName = self.name
      })
    else
      player.room:changeShield(player, 1)
    end
  end,

}
--]]

local shenjun = fk.CreateTriggerSkill{
  name = "jbs__shenjun",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and not data.to.dead
  end,

  on_use = function(self, event, target, player, data)
    local room = player.room
    if  player:isWounded() then
      room:recover({
        who = player,
        num = data.damage,
        recoverBy = player,
        skillName = self.name
      })
    else
      data.to:turnOver()
    end
  end,

}

local shenjun_add = fk.CreateTriggerSkill{
  name = "#jbs__shenjun_add",
  mute=true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and data.to.shield>0 and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + data.to.shield

  end,
}

shenjun:addRelatedSkill(shenjun_add)
erlangshen:addSkill(shenjun)

Fk:loadTranslationTable{
  ["jbs_erlangshen"] = "二郎神",
  ["jbs__shenjun"] = "神君",
  [":jbs__shenjun"] = "锁定技，你对一名角色造成伤害后，回复等同于伤害值的体力；如果你未恢复体力，则令其翻面。你对一名角色造成的伤害+x（x为其护甲值）)",
  ["jbs__xuangong"] = "玄功",
  [":jbs__xuangong"] = "玄功",





  ["#jbs__shenjun_add"]="神君",

}


local zhuoyun=General:new(extension,"jbs_zhuoyun","shu",4,4,General.Female)

Fk:loadTranslationTable{
  ["jbs_zhuoyun"] = "灼云",

}

return extension

