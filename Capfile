# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"


require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require 'capistrano/rvm'
set :rvm_type, :user
set :rvm_ruby_version, '2.3.0@interactive_cv'
set :default_env, { rvm_bin_path: '~/.rvm/bin' }

require "capistrano/rails/assets"
require "capistrano/rails/migrations"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
require "capistrano-resque"