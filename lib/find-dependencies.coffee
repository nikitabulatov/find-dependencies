View = require('./find-dependencies-view')
path = require('path')
fs = require('fs')
{CompositeDisposable} = require('atom')
entryDirs = require('./entry-dirs')

module.exports =
  findDependenciesView: null
  subscriptions: null

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
    for entry in entryDirs
      for atomDir in atom.project.getDirectories()
        items = items.concat(@_getDirs(atomDir, entry))
    @findDependenciesView.setItems(items)

  _getDirs: (atomDir, entry) ->
    root = path.resolve(atomDir.getPath(), entry.dir)
    if @_isDir(root)
      # TODO: make async
      for fileName in fs.readdirSync(root) when @_isDir(path.resolve(root, fileName))
        @_adapt_package(root, fileName, entry)
    else
      []

  _adapt_package: (root, name, entry) ->
    rootPath = path.resolve(root, name)
    filePath = path.resolve(rootPath, entry.mainFile)
    unless @_isFile(filePath)
      filePath = path.resolve(rootPath, fs.readdirSync(rootPath)[0])
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
