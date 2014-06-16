define [
  'backbone'
  'backbone.marionette'
  'coding-rules/views/coding-rules-detail-quality-profiles-view'
  'coding-rules/views/coding-rules-detail-quality-profile-view'
  'coding-rules/views/coding-rules-detail-custom-rules-view'
  'templates/coding-rules'
], (
  Backbone
  Marionette
  CodingRulesDetailQualityProfilesView
  CodingRulesDetailQualityProfileView
  CodingRulesDetailCustomRulesView
  Templates
) ->

  class CodingRulesDetailView extends Marionette.Layout
    template: Templates['coding-rules-detail']


    regions:
      qualityProfilesRegion: '#coding-rules-detail-quality-profiles'
      customRulesRegion: '.coding-rules-detail-custom-rules-section'
      customRulesListRegion: '#coding-rules-detail-custom-rules'
      contextRegion: '.coding-rules-detail-context'


    ui:
      tagsChange: '.coding-rules-detail-tags-change'
      tagInput: '.coding-rules-detail-tag-input'
      tagsEdit: '.coding-rules-detail-tag-edit'
      tagsEditDone: '.coding-rules-detail-tag-edit-done'
      tagsList: '.coding-rules-detail-tag-list'

      descriptionExtra: '#coding-rules-detail-description-extra'
      extendDescriptionLink: '#coding-rules-detail-extend-description'
      extendDescriptionForm: '.coding-rules-detail-extend-description-form'
      extendDescriptionSubmit: '#coding-rules-detail-extend-description-submit'
      extendDescriptionText: '#coding-rules-detail-extend-description-text'
      extendDescriptionSpinner: '#coding-rules-detail-extend-description-spinner'
      cancelExtendDescription: '#coding-rules-detail-extend-description-cancel'

      activateQualityProfile: '#coding-rules-quality-profile-activate'
      activateContextQualityProfile: '.coding-rules-detail-quality-profile-activate'
      changeQualityProfile: '.coding-rules-detail-quality-profile-update'
      createCustomRule: '#coding-rules-custom-rules-create'
      changeCustomRule: '#coding-rules-detail-custom-rule-change'


    events:
      'click @ui.tagsChange': 'changeTags'
      'click @ui.tagsEditDone': 'editDone'

      'click @ui.extendDescriptionLink': 'showExtendDescriptionForm'
      'click @ui.cancelExtendDescription': 'hideExtendDescriptionForm'
      'click @ui.extendDescriptionSubmit': 'submitExtendDescription'

      'click @ui.activateQualityProfile': 'activateQualityProfile'
      'click @ui.activateContextQualityProfile': 'activateContextQualityProfile'
      'click @ui.changeQualityProfile': 'changeQualityProfile'
      'click @ui.createCustomRule': 'createCustomRule'
      'click @ui.changeCustomRule': 'changeCustomRule'


    initialize: (options) ->
      super options

      if @model.get 'params'
        @model.set 'params', _.sortBy(@model.get('params'), 'key')

      unless @model.get 'isTemplate'
        _.map options.actives, (active) =>
          _.extend active, options.app.getQualityProfileByKey active.qProfile
        qualityProfiles = new Backbone.Collection options.actives,
          comparator: 'name'
        @qualityProfilesView = new CodingRulesDetailQualityProfilesView
          app: @options.app
          collection: qualityProfiles
          rule: @model

        qualityProfileKey = @options.app.getQualityProfile()

        if qualityProfileKey
          @contextProfile = qualityProfiles.findWhere qProfile: qualityProfileKey
          unless @contextProfile
            @contextProfile = new Backbone.Model
              key: qualityProfileKey, name: @options.app.qualityProfileFilter.view.renderValue()
          @contextQualityProfileView = new CodingRulesDetailQualityProfileView
            app: @options.app
            model: @contextProfile
            rule: @model
            qualityProfiles: qualityProfiles

          @listenTo @contextProfile, 'destroy', @hideContext

    onRender: ->
      @$el.find('.open-modal').modal();

      if @model.get 'isTemplate'
        @$(@contextRegion.el).hide()
        @$(@qualityProfilesRegion.el).hide()
        @$(@customRulesRegion.el).show()

        customRulesOriginal = @$(@customRulesRegion.el).html()

        @$(@customRulesRegion.el).html '<i class="spinner"></i>'

        customRules = new Backbone.Collection()
        jQuery.ajax
          url: "#{baseUrl}/api/rules/search"
          data:
            template_key: @model.get 'key'
            f: 'name,severity,params'
        .done (r) =>
          customRules.add r.rules

          if customRules.isEmpty() and not @options.app.canWrite
            @$(@customRulesRegion.el).hide()
          else
            @customRulesView = new CodingRulesDetailCustomRulesView
              app: @options.app
              collection: customRules
              templateRule: @model
            @$(@customRulesRegion.el).html customRulesOriginal
            @customRulesListRegion.show @customRulesView

      else
        @$(@customRulesRegion.el).hide()
        @$(@qualityProfilesRegion.el).show()
        @qualityProfilesRegion.show @qualityProfilesView

        if @options.app.getQualityProfile()
          @$(@contextRegion.el).show()
          @contextRegion.show @contextQualityProfileView
        else
          @$(@contextRegion.el).hide()

      that = @
      jQuery.ajax
        url: "#{baseUrl}/api/rules/tags"
      .done (r) =>
        if @ui.tagInput.select2
          # Prevent synchronization issue with navigation
          @ui.tagInput.select2
            tags: _.difference (_.difference r.tags, that.model.get 'tags'), that.model.get 'sysTags'
            width: '300px'

      @ui.tagsEdit.hide()

      @ui.extendDescriptionForm.hide()
      @ui.extendDescriptionSpinner.hide()


    hideContext: ->
      @contextRegion.reset()
      @$(@contextRegion.el).hide()


    changeTags: ->
      if @ui.tagsEdit.show
        @ui.tagsEdit.show()
      if @ui.tagsList.hide
        @ui.tagsList.hide()
      key.setScope 'tags'
      key 'escape', 'tags', => @cancelEdit()


    cancelEdit: ->
      key.unbind 'escape', 'tags'
      if @ui.tagsList.show
        @ui.tagsList.show()
      if @ui.tagInput.select2
        @ui.tagInput.select2 'close'
      if @ui.tagsEdit.hide
        @ui.tagsEdit.hide()


    editDone: ->
      @ui.tagsEdit.html '<i class="spinner"></i>'
      tags = @ui.tagInput.val()
      jQuery.ajax
        type: 'POST'
        url: "#{baseUrl}/api/rules/update"
        data:
          key: @model.get 'key'
          tags: tags
      .done (r) =>
          @model.set 'tags', r.rule.tags
          @cancelEdit()
      .always =>
        @render()


    showExtendDescriptionForm: ->
      @ui.descriptionExtra.hide()
      @ui.extendDescriptionForm.show()
      key.setScope 'extraDesc'
      key 'escape', 'extraDesc', => @hideExtendDescriptionForm()
      @ui.extendDescriptionText.focus()


    hideExtendDescriptionForm: ->
      key.unbind 'escape', 'extraDesc'
      @ui.descriptionExtra.show()
      @ui.extendDescriptionForm.hide()


    submitExtendDescription: ->
      @ui.extendDescriptionForm.hide()
      @ui.extendDescriptionSpinner.show()
      jQuery.ajax
        type: 'POST'
        url: "#{baseUrl}/api/rules/update"
        dataType: 'json'
        data:
          key: @model.get 'key'
          markdown_note: @ui.extendDescriptionText.val()
      .done (r) =>
        @model.set
          htmlNote: r.rule.htmlNote
          mdNote: r.rule.mdNote
        @render()


    activateQualityProfile: ->
      @options.app.codingRulesQualityProfileActivationView.model = null
      @options.app.codingRulesQualityProfileActivationView.show()


    activateContextQualityProfile: ->
      @options.app.codingRulesQualityProfileActivationView.model = @contextProfile
      @options.app.codingRulesQualityProfileActivationView.show()

    createCustomRule: ->
      @options.app.codingRulesCustomRuleCreationView.templateRule = @model
      @options.app.codingRulesCustomRuleCreationView.model = new Backbone.Model()
      @options.app.codingRulesCustomRuleCreationView.show()


    changeCustomRule: ->
      @options.app.codingRulesCustomRuleCreationView.model = @model
      @options.app.codingRulesCustomRuleCreationView.show()


    serializeData: ->
      contextQualityProfile = @options.app.getQualityProfile()
      repoKey = @model.get 'repo'

      _.extend super,
        contextQualityProfile: contextQualityProfile
        contextQualityProfileName: @options.app.qualityProfileFilter.view.renderValue()
        qualityProfile: @contextProfile
        language: @options.app.languages[@model.get 'lang']
        repository: _.find(@options.app.repositories, (repo) -> repo.key == repoKey).name
        canWrite: @options.app.canWrite
        qualityProfilesVisible: not @model.get('isTemplate') and (@options.app.canWrite or not _.isEmpty(@options.actives))
        subcharacteristic: (@options.app.characteristics[@model.get 'debtSubChar'] || '').replace ': ', ' > '
        createdAt: new Date(@model.get 'createdAt')
        allTags: _.union @model.get('sysTags'), @model.get('tags')
