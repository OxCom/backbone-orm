assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
Queue = BackboneORM.Queue
Utils = BackboneORM.Utils
ModelCache = BackboneORM.CacheSingletons.ModelCache
Fabricator = BackboneORM.Fabricator
try WritableStream = require('stream').Writable

option_sets = window?.__test__option_sets or require?('../../../option_sets')
parameters = __test__parameters if __test__parameters?
_.each option_sets, exports = (options) ->
  return if options.embed
  options = _.extend({}, options, parameters) if parameters

  describe "Model.interval #{options.$parameter_tags or ''}#{options.$tags} @slow", ->
    DATABASE_URL = options.database_url or ''
    BASE_SCHEMA = options.schema or {}
    SYNC = options.sync
    BASE_COUNT = 50

    DATE_START = new Date('2013-06-09T08:00:00.000Z')
    DATE_STEP_MS = 1000

    class Flat extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/flats"
      schema: BASE_SCHEMA
      sync: SYNC(Flat)

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
        created_at: Fabricator.date(DATE_START, DATE_STEP_MS)
        updated_at: Fabricator.date
      }, callback)
      queue.await callback

    it 'callback for all models', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {$interval: {key: 'created_at', range: {$gte: DATE_START}, type: 'milliseconds', length: 2*DATE_STEP_MS}},
          ((query, info, callback) ->
            assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
            interval_count++
            Flat.each query,
              ((model, callback) ->
                processed_count++
                callback()
              ), callback
          ), callback

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models - intervalC (CoffeeScript friendly)', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.intervalC {$interval: {key: 'created_at', range: {$gte: DATE_START}, type: 'milliseconds', length: 2*DATE_STEP_MS}}, callback, (query, info, callback) ->
          assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")

          interval_count++
          Flat.eachC query, callback, (model, callback) ->
            processed_count++
            callback()

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models (model and no range)', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {$interval: {key: 'created_at', type: 'milliseconds', length: 2*DATE_STEP_MS}},
          ((query, info, callback) ->
            assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
            interval_count++
            Flat.each query,
              ((model, callback) ->
                processed_count++
                callback()
              ), callback
          ), callback

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models (model and no range) using stream', (done) ->
      return done() unless WritableStream # no streams

      processed_count = 0
      interval_count = 0

      class Counter extends WritableStream
        constructor: -> super {objectMode: true}; @count = 0
        _write: (model, encoding, next) -> @count++; next()

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {$interval: {key: 'created_at', type: 'milliseconds', length: 2*DATE_STEP_MS}},
          ((query, info, callback) ->
            assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
            interval_count++

            Flat.stream(query)
              .pipe(counter = new Counter())
              .on('finish', -> processed_count += counter.count; callback())

          ), callback

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()