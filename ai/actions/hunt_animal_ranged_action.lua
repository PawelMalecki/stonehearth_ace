local Entity = _radiant.om.Entity

local HuntAnimalRanged = radiant.class()

HuntAnimalRanged.name = 'keep hunting this animal'
HuntAnimalRanged.does = 'stonehearth_ace:hunt_animal'
HuntAnimalRanged.args = {
   target = Entity,                  -- the animal to hunt
}
HuntAnimalRanged.priority = 1

function HuntAnimalRanged:start_thinking(ai, entity, args)
   local weapon = stonehearth.combat:get_main_weapon(entity)

   if not weapon or not weapon:is_valid() then
      return
   end

   -- refetch every start_thinking as the set of actions may have changed
   local attack_types = stonehearth.combat:get_combat_actions(entity, 'stonehearth:combat:ranged_attacks')

   if not next(attack_types) then
      -- no ranged attacks
      return
   end

   ai:set_think_output()
end

local ai = stonehearth.ai
return ai:create_compound_action(HuntAnimalRanged)
         :execute('stonehearth:combat:wait_for_global_attack_cooldown')
         :execute('stonehearth:combat:chase_entity_until_targetable', {
            target = ai.ARGS.target,
         })
         :execute('stonehearth:combat:attack_ranged', { target = ai.ARGS.target })
         :execute('stonehearth:combat:set_global_attack_cooldown')