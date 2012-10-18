###
describe 'net/client/statesTest', ->
  describe 'routes', ->
    beforeEach ->
      Tower.Route.clear()

    test 'match /blog', ->
      Tower.Route.draw ->
        @match '/blog', to: 'blogs#index'

      route = Tower.Route.all()[0]

      assert.equal 'blogs.index', route.state

    test '@namespace api @match /blog', ->
      Tower.Route.draw ->
        @namespace 'api', ->
          @match '/blog', to: 'blogs#index'

      route = Tower.Route.all()[0]

      assert.equal 'api.blogs.index', route.state

    test 'define state directly', ->
      Tower.Route.draw ->
        @match '/blog', to: 'blogs#index', state: 'main.index'

      route = Tower.Route.all()[0]

      assert.equal 'main.index', route.state

    # route.parent
    # route.namespace
###