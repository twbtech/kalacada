set :application, 'kato_analytics'
set :repository, 'https://github.com/twbtech/kalacada'

set :branch, 'master'
set :scm, :git
set :rails_env, 'production'
set :ssh_options, forward_agent: true, port: 22

set :user, ENV['KATO_ANALYTICS_SSH_USER']
set :use_sudo, false
set :deploy_to, '/srv/apps/kato_analytics'
set :keep_releases, 10
set :load_rvm, 'source "/home/deploy/.rvm/scripts/rvm"'

default_run_options[:shell] = '/bin/bash'

role :web, ENV['KATO_ANALYTICS_HOST'] # Your HTTP server, Apache/etc
role :app, ENV['KATO_ANALYTICS_HOST'] # This may be the same as your `Web` server
role :db,  ENV['KATO_ANALYTICS_HOST'], primary: true # This is where Rails migrations will run

namespace :deploy do
  task :start do
    run "sudo /bin/bash -c '#{load_rvm} && god start #{application}'"
  end

  task :stop do
    run "sudo /bin/bash -c '#{load_rvm} && god stop #{application}'"
  end

  task :restart, roles: :app, except: { no_release: true } do
    run "sudo /bin/bash -c '#{load_rvm} && god restart app'"
  end

  task :create_symlinks do
    run "ln -s #{shared_path}/config/constants.rb #{latest_release}/config/constants.rb"
    run "ln -s #{shared_path}/config/database.yml #{latest_release}/config/database.yml"
    run "ln -s #{shared_path}/config/solas.yml #{latest_release}/config/solas.yml"
    run "ln -s #{shared_path}/config/secrets.yml #{latest_release}/config/secrets.yml"
  end

  task :migrate do
    run "#{load_rvm} && cd #{latest_release} && RAILS_ENV=#{rails_env} bundle exec rake db:migrate"
  end

  task :bundle do
    run "#{load_rvm} && cd #{latest_release} && RAILS_ENV=#{rails_env} bundle install"
  end

  namespace :assets do
    task :precompile, roles: :web, except: { no_release: true } do
      # delete obsolete assets
      assets_of_all_releases = capture("find #{latest_release}/../*/public/current_assets/ || echo 'no assets yet'").split("\n")
      assets_of_all_releases = assets_of_all_releases.map { |l| l.sub(%r{.*/public/current_assets/}, '') }.uniq.reject { |l| l.start_with?('/srv/') || l.empty? }

      shared_assets = capture("find #{shared_path}/assets/").split("\n")
      shared_assets = shared_assets.map { |l| l.sub(%r{.*/shared/assets/}, '') }.uniq.reject(&:empty?)

      obsolete_assets = (shared_assets - assets_of_all_releases).map { |asset| "#{shared_path}/#{asset}" }

      run "rm -f #{obsolete_assets.join(' ')}" unless obsolete_assets.empty?

      # precompile
      run "#{load_rvm} && cd #{latest_release} && RAILS_ENV=#{rails_env} bundle exec rake assets:precompile --trace"

      # copy public/assets to the "current_assets" so that we know later which ones we actually really need
      run "cp -R #{latest_release}/public/assets #{latest_release}/public/current_assets"

      # copy to shared folder so that we have assets for the current version and for the new version
      run "cp -f -R #{latest_release}/public/assets/* #{shared_path}/assets/"

      # copy all shared assets back into all releases assets folders
      releases = capture("ls #{latest_release}/../").split("\n")

      releases.each do |release|
        target_asset_dir = "#{latest_release}/../#{release}/public/assets/"
        run "mkdir -p #{target_asset_dir}"
        run "cp -R #{shared_path}/assets/* #{target_asset_dir}"
      end
    end
  end
end

after 'deploy:update_code',       'deploy:create_symlinks'
after 'deploy:create_symlinks',   'deploy:bundle'
after 'deploy:bundle',            'deploy:assets:precompile'
after 'deploy:assets:precompile', 'deploy:migrate'
after 'deploy:restart',           'deploy:cleanup'
