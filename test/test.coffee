faucet = require '../index.coffee'
assert = require 'assert'
async = require 'async'
mongoose = require 'mongoose'
db = mongoose.createConnection 'mongodb://localhost:27017/test'
Schema = mongoose.Schema
testSchema = new Schema { i: Number }
model = db.model 'faucettest', testSchema

describe 'mongoose-faucet', ->

  before (done) ->
    model.collection.drop ->
      done()

  describe 'mongoose-faucet tests', ->
    it 'should stream items and iterate through them correctly', (done) ->

      async.each [0..999], (i, cb) ->
        item = new model {i}
        item.save cb
      , (err) ->

        model.find({}).count (err, count) ->
          assert.equal count, 1000

          numberProcessed = 0
          itr = (item, cb) ->
            numberProcessed++
            cb()

          faucet model, {}, itr, {concurrency: 10}, (err) ->
            assert.ifError err
            assert.equal numberProcessed, 1000


            numberProcessed = 0
            faucet model, {i: {$gte: 499}}, itr, {}, (err) ->
              assert.ifError err
              assert.equal numberProcessed, 501
              done()

    it "should work with optional params object", (done) ->
      itr = (item, cb) ->
        cb()

      faucet model, {i: {$gte: 499}}, itr, (err) ->
        assert.ifError err
        done()

    it "should work with to select method", (done) ->
      itr = (item, cb) ->
        assert.ok !item._id
        cb()

      faucet model, {i: {$gte: 499}}, itr, {select: {_id: 0}}, (err) ->
        assert.ifError err
        done()

    it "should work with query res is none", (done) ->
      itr = (item, cb) ->
        cb()

      faucet model, {i: {$lt: 0}}, itr, {select: {_id: 0}}, (err) ->
        assert.ifError err
        done()


    it "should be able to lean things up", (done) ->
      itr = (item, cb) ->
        assert.ok !(item instanceof model)
        cb()

      faucet model, {i: {$gte: 499}}, itr, {lean: true}, (err) ->
        assert.ifError err
        done()

    it "should be able to snapshot the query", (done) ->
      numProc = 0
      itr = (item, cb) ->
        model.findByIdAndUpdate item._id, {$inc: {i: 1000}}, (err) ->
          return cb err if err
          numProc++
          cb()

      model.count {i: {$gte: 499}}, (err, count) ->
        assert.ifError err
        assert.equal count, 501

        faucet model, {i: {$gte: 499}}, itr, {snapshot: true}, (err) ->
          assert.ifError err
          # no idea why this does this...
          assert.equal numProc, 501
          done()

    it "should be able to return batches of items", (done) ->
      numberProcessed = 0
      itr = (items, cb) ->
        assert.equal items.length, 100
        numberProcessed += items.length
        cb()

      faucet model, {}, itr, {batch : 100}, (err) ->
        assert.ifError err
        assert.equal numberProcessed, 1000
        done()


    it "should return the last items in the batch query even if it doesn't fill a full batch", (done) ->
      numberProcessed = 0
      itr = (items, cb) ->
        if numberProcessed != 990
          assert.equal items.length, 99
          numberProcessed += items.length
        else
          assert.equal items.length, 10
          numberProcessed += items.length
        cb()

      faucet model, {}, itr, {batch : 99}, (err) ->
        assert.ifError err
        assert.equal numberProcessed, 1000
        done()

