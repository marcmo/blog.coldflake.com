require 'rake/clean'

CLEAN.include "logfile.log"

desc 'build site'
task :build do
  puts "## Generating site"
  system "jekyll b"
end

desc 'watch & build site'
task :watch do
  puts "## Watching site"
  system "jekyll b -w"
end

desc "Deploy to Github Pages"
task :deploy do
  puts "## Deploying to Github Pages"

  cd "_site" do
    system "git add -A"

    message = "Site updated at #{Time.now.utc}"
    puts "## Commiting: #{message}"
    system "git commit -m \"#{message}\""

    puts "## Pushing generated site"
    system "git push origin gh-pages:gh-pages"

    puts "## Deploy Complete!"
  end
end

desc 'generate AND deploy in one go'
task :gen_deploy => [:build,:deploy]
