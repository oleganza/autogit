require File.dirname(__FILE__) + "/../lib/autogit"

autogit :urls   => ['git://github.com/oleganza/declarations.git'], 
       :commit => '0f500658ab218bde6fcdc1203fb8ae39b16fa895'
     
autogit 'git://github.com/oleganza/gem_console.git', 'master'

autogit 'git://github.com/wycats/merb.git',          '1.0.7.1'

require 'declarations'
require 'gem_console'
require 'merb/lib/merb'
