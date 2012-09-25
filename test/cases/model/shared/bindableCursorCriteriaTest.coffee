describe 'Bindable Cursor Criteria', ->
  cursor = undefined

  class App.BindableCursorCriteriaTest extends Tower.Model
    @field 'string', type: 'String'
    @field 'integer', type: 'Integer'
    @field 'float', type: 'Float'
    @field 'date', type: 'Date'
    @field 'object', type: 'Object', default: {}
    @field 'arrayString', type: ['String'], default: []
    @field 'arrayObject', type: ['Object'], default: []

  describe 'raw cursor', ->
    user    = undefined
    userId  = undefined

    beforeEach (done) ->
      cursor = App.BindableCursorCriteriaTest.cursor()

      App.User.create firstName: 'Lance', (error, record) =>
        user    = record
        userId  = user.get('id')

        done()

    test 'userIdBinding: Ember.Binding.oneWay("App.currentUser.id")', ->
      criteria = Ember.Object.create
        userIdBinding: Ember.Binding.oneWay('Tower.currentUser.id')

    describe 'criteria api', ->
      # Pros: clear
      # Cons: this is the simple case, not many cons, 
      # but it gets harder to read in more complex cases (below)
      # 
      # ...where `Tower.Criteria[method]` wraps `Ember.Binding.oneWay`
      criteria =
        userIdBinding:    Tower.Criteria.eq('App.currentUser.id')
        createdAtBinding: Tower.Criteria.gte('App.currentTimestamp')

      # Cons: too hard to read properties
      criteria =
        userIdBinding:    'App.currentUser.id'
        lteCreatedAtBinding: 'App.currentTimestamp'
        gteCreatedAtBinding: 'App.previousTimestamp'

      # Pros: easy to read properties
      # Cons: not sure what values mean
      criteria =
        userIdBinding:    'App.currentUser.id'
        createdAtBinding:
          '>=': 'App.previousTimestamp'
          '<=': 'App.currentTimestamp'

      # Pros: easy to read properties, values are clear
      # Cons: verbose
      criteria =
        userIdBinding:    Tower.Criteria.eq('App.currentUser.id')
        createdAtBinding:
          '>=': Tower.Criteria.gte('App.previousTimestamp')
          '<=': Tower.Criteria.lte('App.currentTimestamp')

      # Pros: slightly less verbose
      # Cons: createdAtBinding value is too unclear
      criteria =
        userIdBinding:    Tower.Criteria.eq('App.currentUser.id')
        createdAtBinding: [
          Tower.Criteria.gte('App.previousTimestamp')
          Tower.Criteria.lte('App.currentTimestamp')
        ]

      # Pros: easy to read properties
      # Cons: verbose, kind of confusing
      criteria =
        userIdBinding:    Tower.criteria('App.currentUser.id')
        createdAtBinding: Tower.criteria
          Tower.Criteria.gte('App.previousTimestamp'),
          Tower.Criteria.lte('App.currentTimestamp')

      # How the functionality might be implemented if the above...
      _.each criteria, (key, value) ->
        #if key.match(/Binding$/)
        #  # ...
        # but doing this would be doing some of what ember already does,
        # inventing a slightly different API.
        # Maybe not a good idea...

      # Notes:
      # - technically only need to bind to the properties once,
      #   so don't need multiple `App.currentTimestamp` for example,
      #   (say if multiple date props were bound to it).
      # - so, the whole cursor just needs to act like a computable property, such as:
      #   `cursor.observes('App.previousTimestamp', 'App.currentTimestamp', 'App.currentUser.id')`
      # - then whenever even just 1 of those properties changes,
      #   it will iterate through all of the values on the `criteria` hash
      #   and will recompute all the values (most of which will be cached computed properties / bindings),
      #   and then it will re-filter the data matching the cursor.
      # - so the end result is: recompute criteria to find all matching records
      # 
      # With the above in mind, you could have functions on the criteria,
      # which will be executed whenever an observer fires:

      criteria = Tower.criteria(
        userId: -> App.get('currentUser.id')
        createdAt:
          '>=': -> App.get('previousTimestamp')
          '<=': -> App.get('currentTimestamp')
      ).observes('App.currentUser.id', 'App.currentTimestamp', 'App.previousTimestamp')

      # But... that's probably only slightly more optimized than just having bindings on the properties.
      # 
      # You could just make it work without the `Binding` suffix, 
      # but that may be confusing since you probably don't do that in Ember.

      # So this might be the clearest:
      # (it would also probably be the least amount of work)
      criteria =
        userIdBinding: Ember.Binding.oneWay('App.currentUser.id')
        createdAt:
          $gteBinding: Ember.Binding.oneWay('App.previousTimestamp')
          $lteBinding: Ember.Binding.oneWay('App.currentTimestamp')

      # So, the rules could be (for each key/value):
      # 1. If value is a Tower.Criteria one-way binding, then use that,
      # 2. Otherwise, it's a simple/static value

    test 'createdAt: >=: Ember.Binding.oneWay("App.twoIntervalsAgo")', (done) ->
      criteria = Ember.Object.create
        createdAt: Ember.Object.create
          '>=Binding': Ember.Binding.oneWay('Tower.twoIntervalsAgo')

      twoMillisecondsAgo = ->
        now = new Date()
        ago = now - 2
        ago

      setTwoMillisecondsAgo = ->
        Ember.run ->
          Ember.set Tower, 'twoIntervalsAgo', twoMillisecondsAgo()

      setTwoMillisecondsAgo()

      # So this is going to set the "currentDate" (so-to-speak)
      # to 2 milliseconds ago, every 4 milliseconds
      updateInterval = ->
        setTwoMillisecondsAgo()
        endTime   = Ember.get(Tower, 'twoIntervalsAgo')
        endValue  = conditions.createdAt['>=']
        assert.isTrue endTime > startTime, 'startTime > endTime'
        assert.equal endTime, endValue
        done()

      startTime = Ember.get(Tower, 'twoIntervalsAgo')

      cursor.where(criteria)

      conditions = cursor.conditions()

      startValue = conditions.createdAt['>=']

      assert.equal startTime, startValue

      setTimeout(updateInterval, 4)

    test 'params are bindable', (done) ->
      criteria = Ember.Object.create
        userIdBinding: Ember.Binding.oneWay('Tower.currentUser.id')

      cursor.where(criteria)

      Ember.run ->
        Ember.set Tower, 'currentUser', user

      conditions = cursor.toParams().conditions

      assert.isTrue _.isHash(conditions), 'Cursor `conditions` should be a simple hash, not ' + conditions.constructor.toString()

      assert.isTrue !!userId
      assert.equal conditions.userId, userId

      done()