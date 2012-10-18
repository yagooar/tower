# http://livsey.org/blog/2012/10/09/breaking-up-your-routes-in-ember-dot-js/
Tower.Router = Ember.Router.extend
  urlForEvent: (eventName) ->
    path = @._super(eventName);
    if path == ''
      path = '/'
    path
  initialState: 'root'
  # @todo 'history' throws an error in ember
  location:     Ember.HistoryLocation.create()
  root:         Ember.Route.create
    route: '/'
    index: Ember.Route.create(route: '/')
    eventTransitions:
      showRoot: 'root.index'
    showRoot: Ember.State.transitionTo('root.index')

  # Don't need this with the latest version of ember.
  handleUrl: (url, params = {}) ->
    route = Tower.NetRoute.findByUrl(url)

    if route
      params = route.toControllerData(url, params)
      Tower.router.transitionTo(route.state, params)
    else
      console.log "No route for #{url}"

  # createStatesByRoute(Tower.router, 'posts.show.comments.index')
  createControllerActionState: (name, action, route) ->
    name = _.camelize(name, true) #=> postsController

    # @todo tmp hack
    if action == 'show' || action == 'destroy' || action == 'update'
      route += ':id'
    else if action == 'edit'
      route += ':id/edit'

    # isIndexActive, isShowActive
    # actionMethod  = "#{action}#{_.camelize(name).replace(/Controller$/, '')}"
    # 
    # Tower.router.indexPosts = Ember.State.transitionTo('root.posts.index')
    # Need to think about this more...
    # Tower.router[actionMethod] = Ember.State.transitionTo("root.#{_.camelize(name, true).replace(/Controller$/, '')}.#{action}")

    Ember.Route.create
      route: route

      # So you can give it a post and it returns the attributes
      #
      # @todo
      serialize: (router, context) ->
        attributes  = context.toJSON() if context && context.toJSON
        attributes || context # i.e. "params"

      deserialize: (router, params) ->
        params

      enter: (router, transition) ->
        @_super(router, transition)

        console.log "enter: #{@name}" if Tower.debug
        controller  = Ember.get(Tower.Application.instance(), name)

        if controller
          if @name == controller.collectionName
            controller.enter()
          else
            controller.enterAction(action)

      connectOutlets: (router, params) ->
        console.log "connectOutlets: #{@name}" if Tower.debug
        controller  = Ember.get(Tower.Application.instance(), name)

        # controller.call(router, @, params)
        # if @action == state.name, call action
        # else if state.name == @collectionName call @enter
        if controller
          return if @name == controller.collectionName
          controller.call(router, params)

        true

      exit: (router, transition) ->
        @_super(router, transition)

        console.log "exit: #{@name}" if Tower.debug
        controller  = Ember.get(Tower.Application.instance(), name)

        if controller
          if @name == controller.collectionName
            controller.exit()
          else
            controller.exitAction(action)

  insertRoute: (route) ->
    parentState = @root
    names   = route.state.split('.')
    i       = 0

    while i < names.length
      name    = names[i]
      id      = names[0..i].join('.')
      states  = Ember.get(parentState, 'states')

      if !states
        states = {}
        Ember.set(parentState, 'states', states)

      state = Ember.get(states, name)

      if state
        parentState = state
      else
        Tower.router.root[methodName] = Ember.State.transitionTo(route.id)
        Tower.router.root.eventTransitions[methodName] = route.id
        
        state = @createControllerActionState(route.controllerName, route.action, route.path)
        parentState.setupChild(states, name, state)
        parentState = state

      i++

    undefined

# @todo tmp workaround b/c ember will initialize url right when router is created
Tower.router = Tower.Router.PrototypeMixin.mixins[Tower.Router.PrototypeMixin.mixins.length - 1].properties
