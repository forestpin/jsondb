#JSON Database

JSON database is a document database which stores documents as JSON files.
The documents in the database can be maintained by simply editing json
files.

    fs = require 'fs'
    FIND = require './jshelpers/find'

####Load Directory of files
This will load all the files of type `model` recursing over the subdirectories.

    loadDirectory = (options, callback) ->
     path = options.path
     objs = []
     files = []
     err = []
     n = 0

     load = ->
      if n >= files.length
       err = null if err.length is 0
       callback err, objs
       return

      loadFile model: options.model, file: files[n], (e, obj) ->
       if e?
        err.push e
       else
        objs.push obj
       n++
       load()

     FIND path, file: true, filter: /\.json$/, (e, f) ->
      err = e
      err ?= []
      files = f
      load()

####Load file
Loads a single file of type model

    loadFile = (options, callback) ->
     fs.readFile options.file, encoding: 'utf8', (e1, data) ->
      if e1?
       callback msg: "Error reading file: #{options.file}", err: e1,
        new options.model {}, file: options.file
       return

      try
       data = JSON.parse data
      catch e2
       callback msg: "Error parsing file: #{options.file}", err: e2,
        new options.model {}, file: options.file
       return
      if options.model?
       try
        obj = new options.model data, file: options.file
       catch e3
        callback msg: "Error initializing model: #{options.file}", err: e3,
         new options.model {}, file: options.file
        return
       callback null, obj
      else
       callback null, data




## Model class
Introduces class level function initialize and include.
This class is the base class of all other data models.
It has `get` and `set` methods to change values. The structure of
the object is defined by `defaults`.

    class Model
     constructor: ->
      @_init.apply this, arguments

     _initialize: []

####Register initialize functions.
All initializer funcitons in subclasses will be called with the
constructor arguments.

     @initialize: (func) ->
      @::_initialize = @::_initialize.slice()
      @::_initialize.push func

     _init: ->
      for init in @_initialize
       init.apply this, arguments

####Include objects.
You can include objects by registering them with @include. This solves
the problem of single inheritence.

     @include: (obj) ->
      for k, v of obj when not this::[k]?
       this::[k] = v


     model: 'Model'

     _defaults: {}

####Register default key value set.
Subclasses can add to default key-values of parent classes

     @defaults: (defaults) ->
      @::_defaults = JSON.parse JSON.stringify @::_defaults
      for k, v of defaults
       @::_defaults[k] = v

Build a model with the structure of defaults. `options.db` is a reference
to the `Database` object, which will be used when updating the object.
`options.file` is the path of the file, which will be null if this is
a new object.

     @initialize (values, options) ->
      @file = options.file
      @isNew = false
      if not @file?
       @isNew = true

      @values = {}
      values ?= {}
      for k, v of @_defaults
       if values[k]?
        @values[k] = values[k]
       else
        @values[k] = JSON.parse JSON.stringify v

      for k of values
       if not @_defaults[k]?
        throw new Error "Unknown property #{k}"

####Returns key value set

     toJSON: -> JSON.parse JSON.stringify @values

####Get value of a given key

     get: (key) -> @values[key]

####Set key value combination

     set: (obj) ->
      found = null
      for k, v of obj
       if @_defaults[k]?
        @values[k] = v
       else
        found = k

      if found?
       throw new Error "Unknown property #{found}"


###Save the object

     save: (callback) ->
      return unless @file?
      @isNew = false

      data = JSON.stringify @toJSON(), null, ' '
      fs.writeFile @file, data, encoding: 'utf8', (err) ->
       callback err

#Exports

    exports.loadFile = loadFile
    exports.loadDirectory = loadDirectory
    exports.Model = Model
