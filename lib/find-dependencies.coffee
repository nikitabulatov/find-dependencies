View = require('./find-dependencies-view')
path = require('path')
fs = require('fs')
{CompositeDisposable} = require('atom')

module.exports =
  findDependenciesView: null
  subscriptions: null
  config:
    entries:
      type: 'array'
      default: ['node_modules', 'deps[mix.exs]', 'bower_components']
      description: 'Array of entry directories. In brackets enter main file for opening in dependencies package. If file will be not exists then will open first file as fallback.'
      items:
        type: 'string'
    fallbackFileName:
      type: 'string'
      default: 'README.md'
      title: 'Fallback file name'

  activate: (state) ->
    @findDependenciesView = new View
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'find-dependencies:toggle': => @toggle()

  deactivate: ->
    @findDependenciesView.destroy()
    @subscriptions.dispose()

  serialize: ->
    findDependenciesViewState: @findDependenciesView.serialize()

  toggle: ->
    if @findDependenciesView.isVisible()
      @findDependenciesView.hide()
    else
      @findDependenciesView.show()
      @_setItems()

  _setItems: ->
    items = []
    for entry in atom.config.get('find-dependencies.entries')
      entry = @_parseEntry(entry)
      break unless entry
      for atomDir in atom.project.getDirectories()
        items = items.concat(@_getDirs(atomDir, entry))
    @findDependenciesView.setItems(items)

  _parseEntry: (entry) ->
    r = /(\[.*\.*\])/
    if r.test(entry)
      dir = entry.replace(r, '')
      mainFile = entry.match(r)[0].replace(/\[|\]/g, '')
    else
      dir = entry
      mainFile = atom.config.get('find-dependencies.fallbackFileName') || 'README.md'
    {dir, mainFile}

  _getDirs: (atomDir, entry) ->
    root = path.resolve(atomDir.getPath(), entry.dir)
    if @_isDir(root)
      # TODO: make async
      for fileName in fs.readdirSync(root) when @_isDir(path.resolve(root, fileName))
        # TODO: don't push if returns null
        @_adapt_package(root, fileName, entry)
    else
      []

  _adapt_package: (root, name, entry) ->
    rootPath = path.resolve(root, name)
    filePath = path.resolve(rootPath, entry.mainFile)
    unless @_isFile(filePath)
      filePath = path.resolve(rootPath, atom.config.get('find-dependencies.fallbackFileName') || 'README.md')
    unless @_isFile(filePath)
      filePath = path.resolve(rootPath, fs.readdirSync(rootPath)[0])
    unless @_isFile(filePath)
      throw new Erorr("File #{filePath} not exist")
    # TODO: return null if directory is empty or not exist
    {name, filePath, rootDir: entry.dir}

  _isDir: (directory) ->
    try
      fs.statSync(directory)?.isDirectory()
    catch error
      return false

  _isFile: (file) ->
    try
      fs.statSync(file)?.isFile()
    catch error
      return false
