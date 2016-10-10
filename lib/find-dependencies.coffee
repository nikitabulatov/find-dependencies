View = require('./find-dependencies-view')
path = require('path')
fs = require('fs')
{CompositeDisposable} = require('atom')

module.exports = FindModules =
  findModulesView: null
  subscriptions: null

  activate: (state) ->
    @findModulesView = new View
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'find-dependencies:toggle': => @toggle()

  deactivate: ->
    @findModulesView.destroy()
    @subscriptions.dispose()

  serialize: ->
    findModulesViewState: @findModulesView.serialize()

  toggle: ->
    if @findModulesView.isVisible()
      @findModulesView.hide()
    else
      @findModulesView.show()
      @_setItems()

  _setItems: ->
    for dir in atom.project.getDirectories()
      # TODO: use array of modules directories like "node_modules", "bower_components", "deps", etc.
      node_modules = path.resolve(dir.getPath(), 'node_modules')
      @findModulesView.setItems(@_getDirs(node_modules))

  _getDirs: (root_dir) ->
    for file_name in fs.readdirSync(root_dir) when fs.statSync(path.join(root_dir, file_name)).isDirectory()
      @_adapt_package(root_dir, file_name)

  _adapt_package: (root_dir, package_name) ->
    # TODO: use package info. not dir name
    name: package_name, dir: "#{root_dir}/#{package_name}/package.json"
