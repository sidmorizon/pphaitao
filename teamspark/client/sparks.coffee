_.extend Template.sparks,
  sparks: ->
    query = ts.sparks.query()

    order = ts.State.sparkOrder.get()

    sort = {}
    sort[order] = -1

    Sparks.find {$and: query}, {sort: sort}

  initialSparks: ->
    query = ts.sparks.query()

    order = ts.State.sparkOrder.get()

    sort = {}
    sort[order] = -1

    # initial the current page
    ts.State.currentPage.set 2
    Sparks.find {$and: query}, {sort: sort, limit: ts.consts.sparks.PER_PAGE}

  nextBulkSparks: ->
    query = ts.sparks.query()

    order = ts.State.sparkOrder.get()

    sort = {}
    sort[order] = -1

    skipNum = (ts.State.currentPage - 1) * ts.consts.sparks.PER_PAGE
    ts.State.currentPage.set(ts.State.currentPage + 1)

    Sparks.find {$and: query}, {sort: sort, skip: skipNum, limit: ts.consts.sparks.PER_PAGE}

_.extend Template.spark,
  rendered: ->
    #console.log 'spark rendered'
    $parent = $(@firstNode)
    spark = @
    $('.carousel', $parent).carousel
      interval: false
    $('.carousel .item:first-child', $parent).addClass('active')
    #TODO: projects may change so we need to reset editable for .edit-project
    $('.edit-project', $parent).editable(
      type: 'select'
      value: -> @projectId
      placement: 'right'
      name: 'project'
      pk: null
      source: ->
        projects = {}
        for p in ts.projects.all().fetch()
          projects[p._id] = p.name
        return projects
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      if value and sparkId
        Actions.updateSpark sparkId, value, 'project'
    )

    $('.edit-type', $parent).editable(
      type: 'select'
      value: -> @sparkType
      placement: 'right'
      name: 'sparktype'
      pk: null
      source: -> ts.consts.filter.TYPE()
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      if value and sparkId
        Actions.updateSpark sparkId, value, 'type'
    )

    $('.edit-priority', $parent).editable(
      type: 'select'
      source: 1:1, 2:2, 3:3, 4:4, 5:5
      value: -> @priority
      placement: 'right'
      name: 'priority'
      pk: null
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      if value and sparkId
        Actions.updateSpark sparkId, value, 'priority'
    )

    $('.edit-deadline', $parent).editable(
      type: 'date'
      value: -> moment(@deadline)?.format('YYYY-MM-DD')
      placement: 'right'
      name: 'deadline'
      pk: null
      format: 'yyyy-mm-dd'
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      Actions.updateSpark sparkId, value, 'deadline'
    )

    ts.setEditable
      node: $('.edit-points', $parent)
      value: -> @points
      source: -> ts.consts.points.FINISH_SPARK_POINTS
      renderCallback: (e, editable) ->
        value = editable.value
        sparkId = editable.$element.data('id')
        Actions.updateSpark sparkId, value, 'points'

    $('.edit-owners', $parent).editable(
      type: 'text'
      inputclass: 'span4'
      value: ->
        spark = Sparks.findOne _id: @id
        _.pluck(ts.sparks.allOwners(spark), 'username').join(';')
      placement: 'right'
      name: 'owners'
      pk: null
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      owners = _.map value.split(';'), (username) ->
        user = Meteor.users.findOne {teamId: ts.State.teamId.get(), username: username}, {fields: '_id': 1}
        return user?._id

      owners = _.filter owners, (id) -> id
      if owners and sparkId
        Actions.updateSpark sparkId, owners, 'owners'
    ).on('shown', (e, editable) ->
      #console.log e, editable, $(editable.$content).addClass('editable-owners')
      usernames = _.pluck ts.members.all().fetch(), 'username'

      $(editable.$input).select2
        tags: usernames
        placeholder:'Add Responsibles'
        tokenSeparators: [' ']
        separator:';'
    )

    $('.edit-tags', $parent).editable(
      type: 'text'
      inputclass: 'span4'
      #toggle: $('.tags', $parent)
      autotext: 'never'
      emptytext: '<i class="icon-tags"></i>'
      value: ->
        if spark.tags
          return spark.tags.join(';')
        else
          return ''

      placement: 'bottom'
      name: 'tags'
      pk: null
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = spark._id
      if value and sparkId
        Actions.tagSpark sparkId, value
    ).on('shown', (e, editable) ->
      tags = _.pluck ts.tags.all().fetch(), 'name'
      $(editable.$input).select2
        tags: tags
        placeholder: 'Add Tags'
        tokenSeparators: [' ']
        separator: ';'
    )

  events:
    'click .show-comments': (e) ->
      $spark = $(e.currentTarget).closest('.spark')
      $('.comments', $spark).toggle()
      $('.audits', $spark).hide()

    'click .show-audits': (e) ->
      $spark = $(e.currentTarget).closest('.spark')
      $('.audits', $spark).toggle()
      $('.comments', $spark).hide()

    'click .support': (e) ->
      Actions.supportSpark @_id

    'click .finish': (e) ->
      Actions.finishSpark @_id

    'click .verify': (e) ->
      Actions.verifySpark @_id

    'click .upload': (e) ->
      id = @_id
      filepicker.pickMultiple
        container: 'modal'
        services: ['COMPUTER']
        (fpfiles) =>
          #console.log 'uploaded:', id, fpfiles
          Actions.uploadFiles id, fpfiles


    'click .edit': (e) ->
      $node = $('#edit-spark')
      $node.data('id', @_id)
      #console.log 'spark id:', $node.data('id'), @title, @content
      $('.modal-header h3', $node).text "Edit #{@title}"
      $('#spark-edit-title', $node).val @title

      # remove old editor
      editor = ts.editor().panelInstance 'spark-edit-content', hasPanel : true
      editor.removeInstance('spark-edit-content')
      editor = null

      $('#spark-edit-content', $node).html @content

      ts.editor().panelInstance 'spark-edit-content', hasPanel : true

      $('#edit-spark').modal
        keyboard: false
        backdrop: 'static'

    'click .allocate': (e) ->
      alert 'Not finished yet'


  author: ->
    Meteor.users.findOne @authorId

  created: ->
    moment(@createdAt).fromNow()

  positioned: ->
    moment(@positionedAt).fromNow()

  updated: ->
    moment(@updatedAt).fromNow()

  expired: ->
    if @deadline
      return moment(@deadline).fromNow()
    return 'Unassigned'

  typeObj: ->
    obj = ts.sparks.type(@)

  activity: ->
    return @title

  project: ->
    if @projects?.length
      return Projects.findOne @projects[0]
    else
      return null

  supported: ->
    found = ts.sparks.hasSupported @
    if found
      return 'supported'
    return ''

  showSupporters: ->
    items = []
    supporters = Meteor.users.find _id: $in: @supporters
    supporters.forEach (item) ->
      items.push "<li><a href='#'><img src='#{item.avatar}' class='avatar-small' title='#{item.username}'/></a></li>"
    return items.join('\n')

  showOwners: ->
    items = []
    owners = _.map @owners, (id) -> Meteor.users.findOne _id: id

    currentId = owners[0]
    owners.forEach (item) ->
      items.push "<li><a href='#'><img src='#{item.avatar}' class='avatar-small' title='#{item.username}'/></a></li>"
    return items.join('\n')

  showFinishers: ->
    items = []
    finishers = _.map @finishers, (id) -> Meteor.users.findOne _id: id
    finishers.forEach (item) ->
      items.push "<li><a href='#'><img src='#{item.avatar}' class='avatar-small' title='#{item.username}'/></a></li>"

    return items.join('\n')

  showTags: ->
    if @tags
      return @tags.join(', ')
    return 'n/a'

  allocated: ->
    @owners

  supporttedUsers: ->
    Meteor.users.find _id: $in: @supporters

  urgentStyle: ->
    if ts.sparks.isUrgent @
      return 'urgent'
    return ''

  importantStyle: ->
    if ts.sparks.isImportant @
      return 'important'
    return ''

  finishedStyle: ->
    if @finished
      return 'finished'
    return ''

  info: ->
    typeObj = ts.sparks.type @
    text = [typeObj.name]
    if ts.sparks.isUrgent @
      text.push 'Urgent (Expire in 3 days)'

    if ts.sparks.isImportant @
      text.push 'Important (priority with 4 and above)'

    if text.length == 1
      text.push 'Normal'

    return text.join(' | ')

  totalComments: ->
    if @comments
      return @comments.length
    return 0

  reversedComments: ->
    if @comments
      comments = _.clone(@comments)
      comments.reverse()
      return comments
    else
      return []

  totalAudits: ->
    if @auditTrails
      return @auditTrails.length
    return 0

  reversedAudits: ->
    if @auditTrails
      audits = _.clone(@auditTrails)
      audits.reverse()
      return audits
    else
      return []

  canFinish: ->
    if @finished
      return false

    if not @owners[0]
      if ts.isStaff()
        return true
    else if @owners[0] is Meteor.user()?._id
      return true

    return false

  canVerify: ->
    if not @verified and @finished and @authorId is Meteor.userId()
      return true

    return false

  hasImages: ->
    @images?.length > 0

  hasMoreImages: ->
    @images?.length > 1

  hasFiles: ->
    @files?.length > 0

  isCurrentOwner: ->
    Meteor.userId() is @owners[0]

_.extend Template.commentInput,
  events:
    'click .btn': (e) ->
      $form = $(e.currentTarget).closest('form')
      $node = $form.closest('.comment-box')
      content = $('textarea', $form).val()
      Actions.createComment @_id, content
      $('textarea', $form).val('')
      $node.show()

  avatar: ->
    Meteor.user()?.avatar

_.extend Template.comment,
  author: ->
    Meteor.users.findOne @authorId

  created: ->
    moment(@createdAt).fromNow()

