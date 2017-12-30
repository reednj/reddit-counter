job_type :sh, 'cd :path && :task :output'

every 1.minute do
    sh "./_be.sh update_top_threads.rb"
end

every 5.minutes do
    sh "./_be.sh update_data.rb"
end
