assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
Queue = BackboneORM.Queue
Utils = BackboneORM.Utils
ModelCache = BackboneORM.CacheSingletons.ModelCache
Fabricator = BackboneORM.Fabricator

option_sets = window?.__test__option_sets or require?('../../../option_sets')
parameters = __test__parameters if __test__parameters?
_.each option_sets, exports = (options) ->
  options = _.extend({}, options, parameters) if parameters

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Cache Options #{options.$parameter_tags or ''}#{options.$tags}", ->

    after (callback) ->
      queue = new Queue()
      queue.defer (callback) -> ModelCache.reset(callback)
      queue.defer (callback) -> Utils.resetSchemas [Flat], callback
      queue.await callback

    beforeEach (callback) ->
      queue = new Queue(1)
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}, callback)
      queue.defer (callback) -> Utils.resetSchemas [Flat], callback
      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)
      queue.await callback

    describe 'TODO', ->
      it 'TODO', (done) -> done()