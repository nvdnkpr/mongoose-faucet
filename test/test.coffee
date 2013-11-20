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

