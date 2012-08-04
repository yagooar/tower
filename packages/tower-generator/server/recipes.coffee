_ = Tower._

Tower.GeneratorRecipes =
  git:
    run: ->
      @after =>
        @run 'git init'
        @run 'git add .'
        @run 'git commit -m "Initial import."'

  heroku:
    tags: ['services', 'deployment']
    run: ->
      config = @config

      @afterAll =>
        if config['create']
          @say "Creating Heroku app '#{@herokuName}.heroku.com'"
          while !system("heroku create #{@herokuName}")
            @herokuName = @ask("What do you want to call your app?")

        if config['staging']
          @stagingName = "#{@herokuName}-staging"
          @say "Creating staging Heroku app '#{@stagingName}.heroku.com'"
          while !system("heroku create #{@stagingName}")
            @stagingName = @ask("What do you want to call your staging app?")
          @git remote: "rm heroku"
          @git remote: "add production git@heroku.com:#{@herokuName}.git"
          @git remote: "add staging git@heroku.com:#{@stagingName}.git"
          @say "Created branches 'production' and 'staging' for Heroku deploy."

        unless _.isBlank(config['domain'])
          run "heroku addons:add custom_domains"
          run "heroku domains:add #{config['domain']}"

        @git push: "#{if config['staging'] then 'staging' else 'heroku'} master" if config['deploy']

  nodejitsu:
    tags: ['services', 'deployment']
    run: ->

  ec2:
    tags: ['services', 'deployment']
    run: ->

  eco:
    tags: ['templating']
    run: ->

  ejs:
    tags: ['templating']
    run: ->

  jade:
    tags: ['templating']
    run: ->

  s3:
    tags: ['assets']
    run: ->

  cron:
    tags: ['workers']
    run: ->

  neo4j:
    tags: ['databases', 'nosql', 'services']
    run: ->

  mixPanel:
    tags: ['metrics']
    run: ->

  googleAnalytics:
    tags: ['metrics']
    run: ->

  googleApps:
    tags: ['admin']
    run: ->

  customDomain:
    tags: ['admin']
    run: ->

  ssl:
    default: true
    tags: ['security']
    run: ->

  twitterBootstrap:
    tags: ['css']
    run: ->

  foundation:
    tags: ['css']
    run: ->

  mocha:
    tags: ['testing']
    run: ->

  chai:
    tags: ['testing']
    run: ->

  phantomJS:
    tags: ['testing']
    run: ->

  passport:
    tags: ['authentication']
    run: ->

  redis:
    tags: ['databases', 'nosql', 'caching']
    run: ->

  redisToGo:
    tags: ['databases', 'nosql', 'caching', 'redis', 'services']
    run: ->

  sendGrid:
    tags: ['services', 'email']
    run: ->

  mongoLab:
    tags: ['services', 'databases', 'mongodb']
    run: ->

  mongoHQ:
    requiresAny:  ['mongodb']
    runAfter:     ['mongodb', 'heroku']
    category:     'services'
    tags:         ['mongodb']
    run: ->
      config = @config

      if config['useHeroku']
        databaseConfig = url: process.env['MONGOHQ_URL']
      else
        databaseConfig = {}

      @after =>
        @say 'Adding mongohq:free addon (you can always upgrade later)'  
        @system 'heroku addons:add mongohq:free'

    databases = "config/databases.coffee"

    @prependFile databases, databaseConfig

  moonshadosms:
    requiresAny: ['heroku']
    tags: ['services', 'text-messaging']
    run: ->

  # @todo should be setup so it can login as you to facebook to create a new app key,
  #   same for s3, twitter, etc.
  facebook:
    tags: ['authentication']
    run: ->

  travis:
    tags: ['continuous-integration', 'deployment']
    run: ->

  admin:
    tags: ['admin']
    run: ->

for key, value of Tower.GeneratorRecipes
  value.flag ||= '--' + _.parameterize(key) # customDomain becomes "--custom-domain"
  _.extend(value, Tower.t("generator.#{key}"))
