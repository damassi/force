_              = require 'underscore'
Backbone       = require 'backbone'
mediator       = require '../../../lib/mediator.coffee'
track          = require('../../../lib/analytics.coffee').track
FollowProfiles = require '../../../collections/follow_profiles.coffee'

module.exports = class FollowProfileButton extends Backbone.View

  analyticsFollowMessage  : "Followed partner profile from /partners"
  analyticsUnfollowMessage: "Unfollowed partner profile from /partners"

  events:
    'click' : 'onFollowClick'

  initialize: (options) ->
    return unless @collection
    @listenTo @collection, "add:#{@model.get('id')}", @onFollowChange
    @listenTo @collection, "remove:#{@model.get('id')}", @onFollowChange

  onFollowChange: ->
    state = if @collection.isFollowing @model then 'following' else 'follow'
    @$el.attr 'data-state', state

  onFollowClick: (e) ->
    unless @collection
      mediator.trigger 'open:auth', { mode: 'login' }
      return false

    if @collection.isFollowing @model
      track.click @analyticsUnfollowMessage, @model
      @collection.unfollow @model.get('id'),
        success: =>
          @$el.attr('data-state', 'follow')
        error  : =>
          @$el.attr('data-state', 'following')
    else
      track.click @analyticsFollowMessage, @model
      @collection.follow @model.get('id'),
        success: =>
          @$el.attr('data-state', 'following')
        error  : =>
          @$el.attr('data-state', 'follow')

      # Delay label change
      @$el.addClass 'is-clicked'
      setTimeout (=> @$el.removeClass 'is-clicked'), 1500
    false
