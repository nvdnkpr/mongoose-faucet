faucet = require '../index.coffee'
assert = require 'assert'
async = require 'async'
mongoose = require 'mongoose'
db = mongoose.createConnection 'mongodb://localhost:27017/test'
Schema = mongoose.Schema
testSchema = new Schema { i: Number }
model = db.model 'faucet-test', testSchema

describe 'mongoose-faucet', ->

  before (done) ->
    model.collection.drop done

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
              assert.equal numberProcessed, 500
              done()

