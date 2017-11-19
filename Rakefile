require 'shellwords'

def on_prod(command)
    a = `git config --get remote.origin.url`.split(':')
    remote = a.first.strip
    path = a.last.strip
    command = "ssh #{remote} \"cd #{path} && #{command}\""
    puts command
    `#{command}`
end

desc 'push and install on prod'
task :release do
    sh 'git push --follow-tags origin master'
    sh 'git push --follow-tags github master'
    on_prod 'rake restart'
end

task :restart do
    sh 'mkdir -p tmp'
    sh 'touch tmp/restart.txt'
end
