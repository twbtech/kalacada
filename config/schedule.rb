set :output, "#{path}/log/cron.log"
set :job_template, "bash -l -c 'source \"/home/deploy/.rvm/scripts/rvm\" && :job'"

every '0 0 1 * *', roles: [:db] do
  rake 'generate_forecast'
end
