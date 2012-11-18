#
# App Globals
#

kc         = KD.getSingleton "kiteController"
fc         = KD.getSingleton "finderController"
tc         = fc.treeController
{nickname} = KD.whoami().profile
appStorage = new AppStorage "django-installer", "1.0"

#
# App Functions
#

parseOutput = (res, err = no)->
  res = "<br><cite style='color:red'>[ERROR] #{res}</cite><br><br><br>" if err
  {output} = split
  output.setPartial res
  output.utils.wait 100, ->
    output.scrollTo
      top      : output.getScrollHeight()
      duration : 100

checkPath = (formData, callback)->

  {path, domain} = formData

  if path is "" then callback yes
  else
    kc.run "stat /Users/#{nickname}/Sites/#{domain}/website/#{path}"
    , (err, response)->
      if response
        parseOutput "Specified path isn't available, please delete it or select another path!", yes
      callback? err, response

installDjango = (formData, callback)->

  {name, path, domain, timestamp, djangoversion} = formData 

  userDir   = "/Users/#{nickname}/Sites/#{domain}/website/"
  tmpAppDir = "#{userDir}app.#{timestamp}"
  
  instancesDir = "djangoapp-instances"

  # First step: Create our virtualenv and activate it
  commands = [ "virtualenv #{instancesDir}/#{name}"
               "source #{instancesDir}/#{name}/bin/activate" ]

  #Install libraries and django
  commands.push "source #{instancesDir}/#{name}/bin/activate && pip install  django==#{djangoversion}" #look for other versions
  commands.push "source #{instancesDir}/#{name}/bin/activate && pip install flup" # needed for fastcgi
  commands.push "source #{instancesDir}/#{name}/bin/activate && pip install django-snippetscream" # needed for automation of creating superusers
  
  # Create a new django app
  commands.push "source #{instancesDir}/#{name}/bin/activate && cd #{instancesDir}/#{name} && django-admin.py startproject #{name}"
  

  #Modify these places and create a 
  commands.push "echo -e \"INSTALLED_APPS = ( 'snippetscream',) + INSTALLED_APPS\nCREATE_DEFAULT_SUPERUSER = True \" >> #{instancesDir}/#{name}/#{name}/#{name}/settings.py"
  commands.push "sed -i 's/django.db.backends./django.db.backends.sqlite3/g'  #{instancesDir}/#{name}/#{name}/#{name}/settings.py"
  commands.push "sed -i \"s|'NAME': '',|'NAME': '/Users/#{nickname}/#{instancesDir}/#{name}/#{name}/db.sql',|g\" #{instancesDir}/#{name}/#{name}/#{name}/settings.py"
  
   # Create sqlite3 database
  commands.push "source #{instancesDir}/#{name}/bin/activate && python #{instancesDir}/#{name}/#{name}/manage.py syncdb"


  # Hackish I know, but for know its okay :)
  #Create htaccess
  commands.push  "echo -e \"\
RewriteEngine On\n\
RewriteBase /\n\
RewriteRule ^(static/.*)$ - [L]\n\
RewriteCond %{REQUEST_FILENAME} !-f\n\
RewriteRule ^(.*)$ #{name}/django.fcgi/$1 [QSA,L]\" >> .htaccess"

  #Create django.fcgi
  commands.push  "echo -e \"\
#!/usr/bin/python\n\
import sys, os\n\
sys.path.insert(0, '/Users/#{nickname}/#{instancesDir}/#{name}/#{name}')\n\
os.chdir('/Users/#{nickname}/#{instancesDir}/#{name}/#{name}/')\n\
os.environ['DJANGO_SETTINGS_MODULE'] = '#{name}.settings'\n\
from django.core.servers.fastcgi import runfastcgi\n\
runfastcgi(method='threaded', daemonize='false') \">> django.fcgi"

  #Copy files
  commands.push  "mkdir  ~/Sites/${USER}.koding.com/website/#{path}"
  commands.push  "mv django.fcgi  ~/Sites/${USER}.koding.com/website/#{path}"
  commands.push  "mv .htaccess  ~/Sites/${USER}.koding.com/website/#{path}"
  commands.push  "chmod +x  ~/Sites/${USER}.koding.com/website/#{path}/django.fcgi"

  # Admin files to be copied
  commands.push  "cp -r #{instancesDir}/#{name}/lib/python2.6/site-packages/django/contrib/admin/static  ~/Sites/${USER}.koding.com/website/#{path}/"

  # Restart server again
  commands.push  "touch ~/Sites/${USER}.koding.com/website/#{path}/django.fcgi"

 
  # Run commands in correct order if one fails do not continue
  runInQueue = (cmds, index)=>
    command  = cmds[index]
    if cmds.length == index or not command
      parseOutput "<br>#############"
      parseOutput "<br>Django instance successfully installed to: #{userDir}#{path}"
      parseOutput "<br>"
      parseOutput "<br>Some useful information:"
      parseOutput "<br>Virtualenv path      : /Users/#{nickname}/#{instancesDir}/#{name}"
      parseOutput "<br>Db name              : db.sql (/Users/#{nickname}/#{instancesDir}/#{name}/#{name}/db.sql)"      
      parseOutput "<br>Superuser name       : admin"
      parseOutput "<br>Superuser password   : admin"
      parseOutput "<br>"
      parseOutput "<br>#############<br>"
      parseOutput "<br><br><br>"
      appStorage.fetchValue 'blogs', (blogs)->
        blogs or= []
        blogs.push formData
        appStorage.setValue "blogs", blogs
      callback? formData
      
      # It's gonna be le{wait for it....}gendary.
      KD.utils.wait 1000, ->
        appManager.openFileWithApplication "http://#{nickname}.koding.com/#{path}", "Viewer"
      
    else
      parseOutput "$ #{command}<br/>"
      kc.run command, (err, res)=>
        if err
          parseOutput err, yes
        else
          parseOutput res + '<br/>'
          runInQueue cmds, index + 1
       
  # There you go brother ...
  runInQueue commands, 0

