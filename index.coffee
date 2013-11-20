async = require 'async'

module.exports = (model, query, itrFunc, options, cb) ->

  if typeof options == "function"
    cb = options
    options = {}


  q = model.find(query)

  q.snapshot() if options.snapshot
  q.lean() if options.lean

  stream = q.stream()

  queue = async.queue itrFunc, options.concurrency or 100

  queue.saturated = -> stream.pause()
  queue.empty = -> stream.resume()

  stream.on 'data', (doc) ->
    queue.push doc

  stream.on 'error', cb

  stream.on 'close', ->
    async.whilst () ->
      queue.length() > 0
    , (done) ->
      setTimeout done, 1000
    , cb
