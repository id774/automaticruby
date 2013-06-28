Automatic Ruby
==============

**Ruby General Automation Framework**


Description
-----------

This is a general-purpose automatic processing
ruby framework which can extend the functionality
by plug-ins.

See doc/README file.


Get Started
-----------

``` html
[Stable]
$ gem install automatic
$ automatic scaffold
(Make ~/.automatic on your home directory.)
$ automatic -c ~/.automatic/config/example/feed2console.yml
(This process will be output my blog feed to your terminal.)
```

``` html
[Development]
$ git clone git://github.com/automaticruby/automaticruby.git
$ cd automaticruby
$ bundle install --path vendor/gems
$ bin/automatic scaffold
$ bin/automatic -c ~/.automatic/config/example/feed2console.yml
(The same as above.)
```

Specify any recipe with -c option.

``` html
automatic -c <recipe>
```

Example.

``` html
$ automatic -c ~/.automatic/config/example/feed2console.yml
```


What is Recipe?
---------------

Automatic Ruby parses configuration file that was written
in the form of YAML which including variety of information
of associated plug-ins.

This YAML file is called "Recipe".

You can use -c option for specify a file name.

The Recipe has an implicit naming convention.

``` html
plugins:
  - module: MODULE_NAME
    config:
      VARIABLES
```

For more info, refer to the document (doc/README).


Environment
-----------

Ruby 1.9 - 2.0. See Gemfile.


Development
-----------

We need your help.

**Repository**

+ https://github.com/automaticruby/automaticruby

**Issues**

+ https://github.com/automaticruby/automaticruby/issues

**RubyFroge**

+ http://rubyforge.org/projects/automatic/

**RubyGems.org**

+ https://rubygems.org/gems/automatic

**CI**

+ http://jenkins.id774.net/jenkins/


ChangeLog
---------

See doc/ChangeLog file.


Versioning
----------

Releases will be numbered with the follow format:

`<year>.<month>`

This naming convention is to mimic Ubuntu.


Developers
----------

See doc/AUTHORS or following link.

+ https://github.com/automaticruby?tab=members

Project created by

+ http://id774.net
+ http://github.com/id774


License
-------

Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

  http://www.gnu.org/copyleft/gpl.html

Caution!!! This software is NOT under the terms of the LGPL.
See the file doc/COPYING.


