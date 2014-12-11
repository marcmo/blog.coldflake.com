require 'logger'
require 'pp'

$logger = Logger.new('logfile.log')
$logger.level = Logger::DEBUG
$logger.formatter = proc do |s, d, progname, msg|
   "tag_overview_gen: #{d}: #{msg}\n"
end

module Jekyll

  class TagJson < Page
    def initialize(site, base, dir, tag, sorted_tags)
      $logger.debug("TagJson:: tag=#{tag}")
      @site = site
      @base = base
      @dir = dir
      @name = 'tags.json'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag_list.json')
      self.data['tag'] = tag
      self.data['title'] = "Tags"
      self.data['alltags'] = sorted_tags
      self.data['type'] = "tag_type"
    end
  end

  class TagJsonGenerator < Generator
    safe true

    def generate(site)
      $logger.debug "TagJsonGenerator:: generator running, site: #{site}"
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
      json = TagJson.new(site, site.source, dir, tag, sorted)
      json.render(site.layouts, site.site_payload)
      json.write(site.dest)
      site.pages << json
    end
  end

end

