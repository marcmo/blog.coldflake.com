require 'logger'
require 'pp'

$logger = Logger.new('logfile.log')
$logger.level = Logger::DEBUG
$logger.formatter = proc do |s, d, progname, msg|
   "tag_gen: #{d}: #{msg}\n"
end

module Jekyll

  class TagIndex < Page
    def initialize(site, base, dir, tag)
      $logger.debug("TagIndex:: initialize tag=#{tag}")
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag_index.html')
      self.data['tag'] = tag
      self.data['title'] = "Posts Tagged &ldquo;"+tag+"&rdquo;"
      self.data['type'] = "tag_type"
    end
  end

  class TagGenerator < Generator
    safe true

    def generate(site)

      $stdout = StringIO.new
      site.posts.each do |p|
        pp "p.name: #{p.name}"
      end
      $logger.debug "TagGenerator::generator running, site:#{$stdout.string}"

      if site.layouts.key? 'tag_index'
        dir = 'tag'
        write_tag_index(site, dir, "all_tags")
        site.tags.keys.each do |tag|
          write_tag_index(site, File.join(dir, tag), tag)
        end
      end
    end

    def write_tag_index(site, dir, tag)
      index = TagIndex.new(site, site.source, dir, tag)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end

end
