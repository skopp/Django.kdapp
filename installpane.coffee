class InstallPane extends Pane

  constructor:->

    super

    @form = new KDFormViewWithFields
      callback              : @submit.bind(@)
      buttons               :
        install             :
          title             : "Create Django instance"
          style             : "cupid-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
      fields                :
        name                :
          label             : "Name of Django App:"
          name              : "name"
          placeholder       : "type a name for your app..."
          defaultValue      : "My Django Instance"
          validate          :
            rules           :
              required      : "yes"
            messages        :
              required      : "a name for your django app is required!"
          keyup             : => @completeInputs()
          blur              : => @completeInputs()
        domain              :
          label             : "Domain :"
          name              : "domain"
          itemClass         : KDSelectBox
          defaultValue      : "#{nickname}.koding.com"
          nextElement       :
            pathExtension   :
              label         : "/my-django-instance/"
              type          : "hidden"
        path                :
          label             : "Path :"
          name              : "path"
          placeholder       : "type a path for your app..."
          hint              : "leave empty if you want your django app to work on your domain root"
          defaultValue      : "my-django-instance"
          keyup             : => @completeInputs yes
          blur              : => @completeInputs yes
          validate          :
            rules           :
              regExp        : /(^$)|(^[a-z\d]+([-][a-z\d]+)*$)/i
            messages        :
              regExp        : "please enter a valid path!"
          nextElement       :
            timestamp       :
              name          : "timestamp"
              type          : "hidden"
              defaultValue  : Date.now()
        djangoversion       :
          label             : "Django Version :"
          name              : "djangoversion"
          itemClass         : KDSelectBox
          defaultValue      : "1.4.2"

    @form.on "FormValidationFailed", => @form.buttons["Create Django instance"].hideLoader()

    domainsPath = "/Users/#{nickname}/Sites"

    kc.run "ls #{domainsPath} -lpva"
    , (err, response)=>
      if err then warn err
      else
        files = FSHelper.parseLsOutput [domainsPath], response
        newSelectOptions = []

        files.forEach (domain)->
          newSelectOptions.push {title : domain.name, value : domain.name}

        {domain} = @form.inputs
        domain.setSelectOptions newSelectOptions
        

    # Populate Django Version Select Box #TODO: Make it automatically via django-admin.py --version ..
    newVersionOptions = []
    # Implement later, pip only supports stable version
    #newVersionOptions.push {title : "Latest (git)", value : "git"}
    #newVersionOptions.push {title : "1.5a1 (unstable)", value : "1.5"}
    newVersionOptions.push {title : "1.4.2 (stable)", value : "1.4.2"}

    {djangoversion} = @form.inputs
    djangoversion.setSelectOptions newVersionOptions

  completeInputs:(fromPath = no)->

    {path, name, pathExtension} = @form.inputs
    if fromPath
      val  = path.getValue()
      slug = KD.utils.slugify val
      path.setValue val.replace('/', '') if /\//.test val
    else
      slug = KD.utils.slugify name.getValue()
      path.setValue slug

    slug += "/" if slug

    pathExtension.inputLabel.updateTitle "/#{slug}"

      
  # Install 
  submit:(formData)=>

    split.resizePanel 250, 0
    {path, domain, name, djangoversion} = formData
    formData.timestamp = parseInt formData.timestamp, 10
    formData.fullPath = "#{domain}/website/#{path}"

    failCb = =>
      @form.buttons["Create Django instance"].hideLoader()
      @utils.wait 5000, -> split.resizePanel 0, 1

    successCb = =>
      installDjango formData, (path, timestamp)=>
        @emit "WordPressInstalled", formData
        @form.buttons["Create Django instance"].hideLoader()
    
    checkPath formData, (err, response)=>
        console.log arguments
        if err # means there is no such folder
            successCb()
        else # there is a folder on the same path so fail.
            failCb()

  pistachio:-> "{{> @form}}"
