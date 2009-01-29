require File.dirname(__FILE__) + "/../lib/gitdep"

gitdep :urls   => ['git://github.com/oleganza/declarations.git'], 
       :commit => '0f500658ab218bde6fcdc1203fb8ae39b16fa895'
     
gitdep 'git://github.com/oleganza/gem_console.git', 'master'

gitdep 'git://github.com/wycats/merb.git',          '1.0.7.1'

require 'declarations'
require 'gem_console'
require 'merb/lib/merb'
