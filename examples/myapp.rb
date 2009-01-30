require File.dirname(__FILE__) + "/../lib/autogit"

# First rule is executed after second rule

AutoGit.rewrite(/gitbub/i) do |url|
  url.gsub(/gitbub/i, "github")
end

AutoGit.rewrite("gitdubb") do |url|
  url.gsub(/gitdubb/i, "GiTBuB")
end

AutoGit.rewrite("lolcatz", nil)

autogit([
    'git://github.com/lolcatz/repo.git', # this will be cleared by a rule
    'git@localhost/declarations.git',
    'git://gitdubb.com/oleganza666666/declarations.git',
    'git://gitdubb.com/oleganza/declarations.git'
  ], 
  '0f500658ab218bde6fcdc1203fb8ae39b16fa895')
autogit 'git://gitdubb.com/oleganza/gem_console.git', 'master'

require 'declarations'
require 'gem_console'
