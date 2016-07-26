_ = require 'underscore'
Backbone = require 'backbone'
sinon = require 'sinon'
Partner = require '../../../../models/partner.coffee'
Profile = require '../../../../models/profile.coffee'
Articles = require '../../../../collections/articles.coffee'
benv = require 'benv'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'
fixtures = require '../../../../test/helpers/fixtures.coffee'

describe 'ArticlesAdapter', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        sd: ARTSY_EDITORIAL_CHANNEL: '123'
      $.fn.imagesLoaded = sinon.stub()
      $.fn.waypoint = sinon.stub()
      @ArticlesAdapter = benv.requireWithJadeify(
        (resolve __dirname, '../../client/articles'), ['articleTemplate']
      )
      @ArticlesGridView = benv.requireWithJadeify(
        (resolve __dirname, '../../../../components/articles_grid/view'), ['template', 'button', 'figure', 'empty']
      )
      @ArticleView = benv.requireWithJadeify(
        (resolve __dirname, '../../../../components/article/client/view'), ['editTemplate', 'relatedTemplate', 'calloutTemplate']
      )
      @ArticleView.__set__ 'initCarousel', sinon.stub()
      sinon.stub @ArticleView::, 'fillwidth'
      @ArticlesAdapter.__set__ 'ArticlesGridView', @ArticlesGridView
      @ArticlesAdapter.__set__ 'ArticleView', @ArticleView
      Backbone.$ = $
      sinon.stub Backbone, 'sync'
      benv.render resolve(__dirname, '../../templates/index.jade'), {
        profile: new Profile fabricate 'partner_profile'
        sd: { PROFILE: fabricate 'partner_profile' }
        asset: (->)
        params: {}
      }, =>
        done()

  afterEach ->
    Backbone.sync.restore()
    benv.teardown()

  describe '#constructor', ->

    beforeEach ->
      @renderArticlesGrid = sinon.stub @ArticlesAdapter.prototype, 'renderArticlesGrid'
      @renderArticle = sinon.stub @ArticlesAdapter.prototype, 'renderArticle'

    afterEach ->
      @renderArticlesGrid.restore()
      @renderArticle.restore()

    it 'calls #renderArticlesGrid if /articles', ->
      sinon.stub(@ArticlesAdapter.prototype, 'isArticle').returns false
      view = new @ArticlesAdapter
        profile: new Profile fabricate 'partner_profile'
        partner: new Partner fabricate 'partner'
        cache: {}
        el: ''
      @renderArticlesGrid.callCount.should.equal 1
      @renderArticle.callCount.should.equal 0
      @ArticlesAdapter.prototype.isArticle.restore()

    it 'calls #renderArticle if /article/', ->
      sinon.stub(@ArticlesAdapter.prototype, 'isArticle').returns true
      view = new @ArticlesAdapter
        profile: new Profile fabricate 'partner_profile'
        partner: new Partner fabricate 'partner'
        cache: {}
        el: ''
      @renderArticlesGrid.callCount.should.equal 0
      @renderArticle.callCount.should.equal 1
      @ArticlesAdapter.prototype.isArticle.restore()

  describe '#renderArticlesGrid', ->

    beforeEach ->
      sinon.stub(@ArticlesAdapter.prototype, 'isArticle').returns false
      @view = new @ArticlesAdapter
        profile: new Profile fabricate 'partner_profile'
        partner: new Partner fabricate 'partner'
        cache: {}
        el: $('body')

    afterEach ->
      @ArticlesAdapter.prototype.isArticle.restore()

    it 'renders a loading spinner', ->
      @view.el.html().should.containEql 'loading-spinner'

    it 'removes the loading spinner when articles have loaded', ->
      @view.collection.add fabricate 'article'
      @view.collection.trigger 'sync'
      @view.el.html().should.not.containEql 'loading-spinner'

    it 'renders a grid of articles', ->
      @view.collection.add fabricate 'article'
      @view.collection.trigger 'sync'
      @view.el.html().should.containEql 'On The Heels of A Stellar Year in the West'
      @view.el.html().should.containEql 'Artsy Editorial'

  describe '#renderArticle', ->

    beforeEach ->
      sinon.stub(@ArticlesAdapter.prototype, 'isArticle').returns true
      sinon.stub window.location, 'replace'
      @view = new @ArticlesAdapter
        profile: new Profile fabricate 'partner_profile'
        partner: new Partner fabricate 'partner'
        cache: {}
        el: $('body')

    afterEach ->
      @ArticlesAdapter.prototype.isArticle.restore()
      window.location.replace.restore()

    it 'redirects to the partner overview if the article is not found', ->
      Backbone.sync.args[0][2].error()
      window.location.replace.called.should.be.true()
      window.location.replace.args[0][0].should.equal '/gagosian'

    it 'displays an article', ->
      Backbone.sync.args[0][2].success fixtures.article
      @view.el.html().should.containEql 'Top Ten Booths'
      @view.el.html().should.containEql 'article-container'
