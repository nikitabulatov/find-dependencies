# TODO: Use glob for matching file patterns
# TODO: Make async fs things
# TODO: Tests
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
    result = []
    if @_isDir(root)
      for fileName in fs.readdirSync(root) when @_isDir(path.resolve(root, fileName))
        pack = @_adapt_package(root, fileName, entry)
        result.push(pack) if pack
    result

  _adapt_package: (root, name, entry) ->
    rootPath = path.resolve(root, name)
    filePath = path.resolve(rootPath, entry.mainFile)
    unless @_isFile(filePath)
      filePath = path.resolve(rootPath, atom.config.get('find-dependencies.fallbackFileName') || 'README.md')
    unless @_isFile(filePath)
      firstFile = @_getFirstFile(rootPath)
      filePath = if firstFile then path.resolve(rootPath, firstFile) else null
    if filePath and @_isFile(filePath)
      return {name, filePath, rootDir: entry.dir}
    else
      return null

  _getFirstFile: (dir) ->
    for p in fs.readdirSync(dir)
      p = path.resolve(dir, p)
      return p if @_isFile(p)
    null

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
