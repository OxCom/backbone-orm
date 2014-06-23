try BackboneORM = require 'backbone-orm' catch err then BackboneORM = require('../../backbone-orm')
Queue = BackboneORM.Queue

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./collection/sync')(options, callback)
  queue.await callback
