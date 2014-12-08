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

desc 'create new post with rake newPost["my new post"]'
task :newPost, [:name] do |t,args|
  t = Time.now
  name = args[:name].gsub!(/\s/,'-')
  puts "creating next post: #{name}"
  postName = t.strftime("%Y-%m-%d-#{name}.md")
  post = File.join("_posts",postName)
  if File.exists?(post)
    puts "post with the name #{postName} already exists!"
  else
    puts "creating......post with the name #{postName}"
    p = File.new(post, "w")
    p.puts "---"
    p.puts "layout:     post"
    p.puts "title: #{name.split('-').each{|word| word.capitalize!}.join(' ')}"
    p.puts "subtitle: xxxxxxxx"
    p.puts 'author:     "Oliver Mueller"'
    p.puts "tags: []"
    p.puts 'header-img: "img/missing.jpg"'
    p.puts "---"

  end
end

