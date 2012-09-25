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

    afterEach ->
      delete Tower['currentUser']
      delete Tower['previousTimestamp']
      delete Tower['currentTimestamp']
      delete Tower['currentTags']
      delete Tower['currentOrder']

    test 'userIdBinding: Ember.Binding.oneWay("App.currentUser.id")', ->
      criteria = Ember.Object.create
        userIdBinding: Ember.Binding.oneWay('Tower.currentUser.id')

    describe 'criteria api', ->
      # Ember.Object.create
      #   'updatedAt$gteBinding': Ember.Binding.oneWay('Tower.previousTimestamp')
      # Ember.observer works with these attributes:
      # Ember.observer(((criteria, key) ->), 'userId', 'createdAt.$gte', 'createdAt.$lte')
      #criteriaDidChange: Ember.observer(((criteria, key) ->
      #  Ember.set(@, 'isDirty', true)
      #), 'createdAt.$lte', 'userId')
      criteria = undefined

      defineCriteria = ->
        Ember.Object.create
          userIdBinding: Ember.Binding.oneWay('Tower.currentUser.id')
          createdAt: Ember.Object.create
            $gteBinding: Ember.Binding.oneWay('Tower.previousTimestamp')
            $lteBinding: Ember.Binding.oneWay('Tower.currentTimestamp')
          tags: Ember.Object.create
            $inBinding: Ember.Binding.oneWay('Tower.currentTags')
          orderBinding: Ember.Binding.oneWay('Tower.currentOrder')
          isDirty: false

      # Maybe we could just be very explicit?
      defineMoreExplicitCriteria = ->
        Ember.Object.create
          userIdBinding: Ember.Binding.oneWay('Tower.currentUser.id')
          createdAtGreaterThanOrEqualToBinding: Ember.Binding.oneWay('Tower.previousTimestamp')
          createdAtLessThanOrEqualToBinding: Ember.Binding.oneWay('Tower.currentTimestamp')
          tagsInBinding: Ember.Binding.oneWay('Tower.currentTags')
          orderBinding: Ember.Binding.oneWay('Tower.currentOrder')
          isDirty: false

      beforeEach ->
        criteria = defineCriteria()

      test 'finds nested observable keys', ->
        observes = Tower.findObservedKeys(criteria)

        assert.deepEqual observes.sort(), [
          'Tower.currentUser.id',
          'Tower.currentOrder',
          'Tower.previousTimestamp',
          'Tower.currentTimestamp',
          'Tower.currentTags'
        ].sort()

      test 'sets `isDirty` to true when an observed property changes', (done) ->
        cursor.where(criteria)

        conditions = cursor.conditions()

        assert.isUndefined conditions['userId']
        assert.isUndefined conditions['createdAt']['$gte']
        assert.isUndefined conditions['createdAt']['$lte']
        #assert.isUndefined conditions['updatedAt.$gte']
        assert.isUndefined conditions['tags']['$in']
        assert.isFalse criteria.isDirty

        previousTimestamp = (new Date).getTime() - 200
        currentTimestamp  = (new Date).getTime() - 100
        currentTags       = ['javascript']
        currentOrder      = ['createdAt', 'DESC'] # Tower.Criteria.desc('createdAt')

        Ember.run ->
          Ember.setProperties Tower,
            currentUser:        user
            previousTimestamp:  previousTimestamp
            currentTimestamp:   currentTimestamp
            currentTags:        currentTags

        conditions = cursor.conditions()

        assert.equal conditions['userId'], user.get('id')
        assert.equal conditions['createdAt']['$gte'], previousTimestamp
        assert.equal conditions['createdAt']['$lte'], currentTimestamp
        #assert.equal conditions['updatedAt.$gte'], previousTimestamp
        assert.equal conditions['tags']['$in'], currentTags

        Ember.run ->
          currentTags.pushObject('ember')

        assert.equal conditions['tags']['$in'], currentTags
        assert.isTrue criteria['isDirty']

        # @todo ...
        # 
        # 1. Cursor needs to know when (possibly nested) bindings execute somehow.
        #   This will tell us when to re-filter the cursor.
        # 2. 

        done()

      test 'Tower.findBindings', ->
        bindings = Tower.findBindings(criteria)
        assert.equal bindings.length, 5

      test 'array observing', (done) ->
        cursor.where(criteria)

        conditions = cursor.conditions()

        assert.isUndefined conditions['tags']['$in']
        assert.isFalse criteria.isDirty

        currentTags       = ['javascript']

        Ember.run ->
          Ember.setProperties Tower,
            currentTags:        currentTags

        conditions = cursor.conditions()

        assert.equal conditions['tags']['$in'], currentTags
        assert.isTrue criteria['isDirty']

        Ember.set(criteria, 'isDirty', false)

        Ember.run ->
          currentTags.pushObject('ember')

        assert.equal conditions['tags']['$in'], currentTags
        assert.isTrue criteria['isDirty'], 'Must run observer if array length changes'

        done()

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

      # @todo ?
      # assert.isTrue _.isHash(conditions), 'Cursor `conditions` should be a simple hash, not ' + conditions.constructor.toString()

      assert.isTrue !!userId
      assert.equal conditions.userId, userId

      done()