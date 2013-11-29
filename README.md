mongoose-faucet
===============

An easy way to process large document sets with mongoose.

If you have ever tried to run some migration operation on a few million documents, you have probably run into problems with either memory usage or parallelization.

Faucet helps by iterating your mongoose model in a throttled way so all you have to worry about is your single update

# Install
```
npm install mongoose-faucet
```

## API
```
faucet = require "mongoose-faucet"
faucet MongooseModel, query, processingFunction, [options], cb
```
where
- `query` is a json mongo query
- `processingFunction` is a function that takes a document and a callback

`options` is an optional parameter hash that defines a few things, here are the defaults
```
{
  "concurrency" : 100, // Default: 100. The number of concurrent updates that can run
  "snapshot": true, // Default: true. Run a snapshot query, this is often neccesary as iterating over a cursor can present the same document multiple times.
  "lean" : false // Default: false. Lean your mongoose documents
  "batch" : 1000 // If batch is defined, processingFunction will be passed an array of size "batch" instead of a single item
}

```

