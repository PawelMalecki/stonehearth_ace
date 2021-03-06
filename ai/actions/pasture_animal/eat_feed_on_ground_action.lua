local EatFeedOnGround = radiant.class()

EatFeedOnGround.name = 'eat feed from ground'
EatFeedOnGround.does = 'stonehearth:eat'
EatFeedOnGround.args = {
   food_quality = {
      type = 'number',
      default = stonehearth.ai.NIL,
   },
   food_preferences = {
      type = 'string',
      default = stonehearth.ai.NIL,
   },
   food_priority = {
      type = 'number',
      default = stonehearth.ai.NIL,
   }
}
EatFeedOnGround.priority = {0, 1}

function EatFeedOnGround:start_thinking(ai, entity, args)
   self._pasture = nil
   self._ai = ai
   self._ready = false
   self._entity = entity

   local pasture_tag = entity:get_component('stonehearth:equipment'):has_item_type('stonehearth:pasture_equipment:tag')
   if pasture_tag then
      local pasture = pasture_tag:get_component('stonehearth:shepherded_animal'):get_pasture()
      if pasture and pasture:is_valid() then
         self._pasture = pasture
         self._on_feed_changed_listener = radiant.events.listen(pasture, 'stonehearth:shepherd_pasture:feed_changed', self, self._rethink)
         self._calorie_listener = radiant.events.listen(self._entity, 'stonehearth:expendable_resource_changed:calories', self, self._rethink)
         --self._timer = stonehearth.calendar:set_interval("eat_action hourly", '10m+5m', function() self:_rethink() end, '20m')
         self:_rethink()  -- Safe to do sync since it can't call both clear_think_output and set_think_output.
      end
   end
end

function EatFeedOnGround:_rethink()
   local consumption = self._entity:get_component('stonehearth:consumption')
   if not consumption then
      self:_mark_unready()
      return
   end

   local hunger_score = consumption:get_hunger_score()
   local min_hunger_to_eat = consumption:get_min_hunger_to_eat_now()

   local feed_entity = self._pasture and self._pasture:get_component('stonehearth:shepherd_pasture'):get_feed()
   
   if feed_entity and hunger_score >= min_hunger_to_eat then
      self:_mark_ready(feed_entity)
   else
      self:_mark_unready()
   end

   self._ai:set_utility(hunger_score)
end

function EatFeedOnGround:_mark_ready(feed_entity)
   if not self._ready then
      self._ready = true
      self._ai:set_think_output({
         feed = feed_entity
      })
      radiant.events.trigger_async(self._entity, 'stonehearth:entity:looking_for_food')
   end
end

function EatFeedOnGround:_mark_unready()
   if self._ready then
      self._ready = false
      self._ai:clear_think_output()
      radiant.events.trigger_async(self._entity, 'stonehearth:entity:stopped_looking_for_food')
   end
end

function EatFeedOnGround:stop_thinking(ai, entity)
   if self._on_feed_changed_listener then
      self._on_feed_changed_listener:destroy()
      self._on_feed_changed_listener = nil
   end
   if self._calorie_listener then
      self._calorie_listener:destroy()
      self._calorie_listener = nil
   end
   -- if self._timer then
   --    self._timer:destroy()
   --    self._timer = nil
   -- end
end

local ai = stonehearth.ai
return ai:create_compound_action(EatFeedOnGround)
   :execute('stonehearth:goto_entity', {entity = ai.PREV.feed})
   :execute('stonehearth:eat_feed_adjacent', { food = ai.BACK(2).feed })
