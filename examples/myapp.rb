require File.dirname(__FILE__) + "/../lib/autogit"

autogit ['git://github.com/oleganza/declarations.git'], '0f500658ab218bde6fcdc1203fb8ae39b16fa895'
autogit 'git://github.com/oleganza/gem_console.git', 'master'

require 'declarations'
require 'gem_console'
