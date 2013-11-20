async = require 'async'

module.exports = (model, query, itrFunc, options, cb) ->

  if typeof options == "function"
    cb = options
    options = {}

  options.snapshot ||= true
  options.lean ||= false

  stream = model.find(query).snapshot(options.snapshot).lean(options.lean).stream()

  queue = async.queue itrFunc, options.concurrency or 100

  queue.saturated = -> stream.pause()
  queue.empty = -> stream.resume()

  stream.on 'data', (doc) ->
    queue.push doc

  stream.on 'error', cb

  stream.on 'close', ->
    stream.resume()
    queue.drain = ->
      cb()
