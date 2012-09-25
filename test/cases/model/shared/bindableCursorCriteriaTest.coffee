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

    test 'userIdBinding: Ember.Binding.oneWay("App.currentUser.id")', ->
      criteria = Ember.Object.create
        userIdBinding: Ember.Binding.oneWay('Tower.currentUser.id')

    test 'criteria api', (done) ->
      criteria = Ember.Object.create
        userIdBinding: Ember.Binding.oneWay('Tower.currentUser.id')
        createdAt: Ember.Object.create
          $gteBinding: Ember.Binding.oneWay('Tower.previousTimestamp')
          $lteBinding: Ember.Binding.oneWay('Tower.currentTimestamp')

      cursor.where(criteria)

      conditions = cursor.conditions()

      assert.isUndefined conditions['userId']
      assert.isUndefined conditions['createdAt']['$gte']
      assert.isUndefined conditions['createdAt']['$lte']

      previousTimestamp = (new Date).getTime() - 200
      currentTimestamp  = (new Date).getTime() - 100

      Ember.run ->
        Ember.setProperties Tower,
          currentUser:        user
          previousTimestamp:  previousTimestamp
          currentTimestamp:   currentTimestamp

      conditions = cursor.conditions()

      assert.equal conditions['userId'], user.get('id')
      assert.equal conditions['createdAt']['$gte'], previousTimestamp
      assert.equal conditions['createdAt']['$lte'], currentTimestamp

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

      assert.isTrue _.isHash(conditions), 'Cursor `conditions` should be a simple hash, not ' + conditions.constructor.toString()

      assert.isTrue !!userId
      assert.equal conditions.userId, userId

      done()