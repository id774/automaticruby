Automatic Ruby
==============

**Ruby General Automation Framework**

See doc/README file.


Get Started
-----------

Installation.

``` html
gem install automatic
```

Specify any recipe with -c option.

``` html
automatic -c <recipe>
```

Example.

``` html
$ automatic -c config/feed2console.yml
```


What is Recipe?
---------------

Automatic Ruby parses configuration file that was written
in the form of YAML which including variety of information
of associated plug-ins.

This YAML file is called "Recipe".

When you start automatic ruby without argument -c option,
the config/default.yml is called. You can use -c option for
specify a file name.

For more info, refer to the document (doc/README).


Environment
-----------

After ruby 1.8.


Development
-----------

We need your help.

**Repository**

+ https://github.com/id774/automaticruby

**Issues**

+ https://github.com/id774/automaticruby/issues

**RubyFroge**

+ http://rubyforge.org/projects/automatic/

**CI**

+ http://id774.net/jenkins/


How to Join
-----------

1. Fork the repository.
2. Write new plugin or existing code improvement.
3. Send pull request!

After that, we will give you the right to commit for a quick fix finely.


Coding Rule
-----------

+ 2 tabs (Soft Tabs).
+ Remove trailing spaces.
+ Namespace and conventions, see the existing code.
+ {} is recommended than do end (To avoid end end end,,).
+ RDoc Header is written by creator of the file.
+ Write tests with RSPec.
+ Aim at 100% coverage.


ChangeLog
---------

See doc/ChangeLog file.


Versioning
----------

Releases will be numbered with the follow format:

`<year>.<month>`

This naming convention is to mimic the Ubuntu.


Author
------

**774**

+ http://id774.net
+ http://github.com/id774


Developers
----------

See doc/AUTHORS.


Copyright and license
---------------------

Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

  http://www.gnu.org/copyleft/gpl.html

Caution!!! This software is NOT under the terms of the LGPL.
See the file doc/COPYING.


