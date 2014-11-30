require 'logger'
require 'pp'

$logger = Logger.new('logfile.log')
$logger.level = Logger::DEBUG
$logger.formatter = proc do |s, d, progname, msg|
   "tag_overview_gen: #{d}: #{msg}\n"
end

module Jekyll

  class TagOverviewIndex < Page
    def initialize(site, base, dir, tag, all)
      $logger.debug("TagOverviewIndex:: tag=#{tag}")
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag_overview.html')
      self.data['tag'] = tag
      self.data['title'] = "Tags"
      self.data['alltags'] = all
      self.data['type'] = "tag_overview_type"
    end
  end

  class TagOverviewGenerator < Generator
    safe true

    def generate(site)
      $logger.debug "TagOverviewGenerator:: generator running, site: #{site}"
      if site.layouts.key? 'tag_overview'
        write_tag_index(site, 'tag', "all_tags")
      end
    end

    def write_tag_index(site, dir, tag)
      alltags = []
      site.posts.each do |p|
        p.tags.each do |t|
          alltags << t
        end
      end
      counts = Hash.new(0)
      alltags.each do |t|
        counts[t] += 1
      end
      sorted = counts.sort { |a,b| b[1] <=> a[1] }
      index = TagOverviewIndex.new(site, site.source, dir, tag, sorted)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end

end
