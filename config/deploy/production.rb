set :branch, 'master'
set :stage, :production
server '138.68.70.82', user: 'deploy', roles: %w{ web app db}
set :bundle_binstubs, nil

role :resque_worker, "138.68.70.82"

set :workers, { "geoserver_tasks" => 1, "documents" => 1 }