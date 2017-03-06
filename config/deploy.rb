# config valid only for current version of Capistrano
lock "3.7.2"

set :application, "interactive_cv"
set :repo_url, "git@github.com:ghostinshadow/interactive_cv.git"

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/interactive_cv"

# Default value for :format is :airbrussh.
set :format, :airbrussh
set :default_stage, 'production'
set :rvm_type, :user
set :rvm_ruby_version, '2.3.0@interactive_cv'
set :default_env, { rvm_bin_path: '~/.rvm/bin' }

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/local_env.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads}

set :ssh_options, {:forward_agent => true, :keepalive => true}

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
  after :restart, "resque:restart"
  after :restart, "resque:scheduler:restart"

end