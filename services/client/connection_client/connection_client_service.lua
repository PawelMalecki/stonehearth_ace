--[[
   this service listens for relevant changes to the server connection service
   used for: render colors for connection types
]]

local Point3 = _radiant.csg.Point3
local ConnectionUtils = require 'lib.connection.connection_utils'

local combine_tables = ConnectionUtils.combine_tables
local combine_type_tables = ConnectionUtils.combine_type_tables

local log = radiant.log.create_logger('connection_client')

local ConnectionClientService = class()

function ConnectionClientService:initialize()
   self._connection_colors = {}
   self._connections = {}

   self:_setup_connection_types()
end

function ConnectionClientService:destroy()
   self:destroy_listeners()
end

function ConnectionClientService:destroy_listeners()
   if self._connections_trace then
      self._connections_trace:destroy()
      self._connections_trace = nil
   end
end

function ConnectionClientService:update_client_connections()
   _radiant.call_obj('stonehearth_ace.connection', 'get_connections_data_command')
      :done(function (response)
         self._connections = response.connections
      end)
end

function ConnectionClientService:_setup_connection_types()
   _radiant.call_obj('stonehearth_ace.connection', 'get_connection_types_command')
      :done(function(response)
         for name, type in pairs(response.types) do
            local colors = {}
            if type.available_color then
               colors.available_color = Point3(unpack(type.available_color))
            end
            if type.connected_color then
               colors.connected_color = Point3(unpack(type.connected_color))
            end

            self._connection_colors[name] = colors
         end
      end)
end

function ConnectionClientService:get_connection_type_colors(type)
   return self._connection_colors[type]
end

function ConnectionClientService:get_entity_connection_stats(entity_id)
   return self._connections[entity_id] or {}
end

return ConnectionClientService