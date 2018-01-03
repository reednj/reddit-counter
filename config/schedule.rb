job_type :sh, 'cd :path && :task :output'

every 2.minute do
    sh "./_be.sh update_top_threads.rb"
end

every 15.minutes do
    sh "./_be.sh update_data.rb"
end
