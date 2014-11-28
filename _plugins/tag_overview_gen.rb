require 'set'

module Jekyll

  class TagOverviewIndex < Page
    def initialize(site, base, dir, tag, all)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag_overview.html')
      self.data['tag'] = tag
      self.data['title'] = "Tags"
      self.data['alltags'] = all
    end
  end

  class TagOverviewGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'tag_overview'
        write_tag_index(site, 'tag', "all_tags")
      end
    end

    def write_tag_index(site, dir, tag)
      alltags = Set.new
      site.posts.each do |p|
        p.tags.each do |t|
          alltags.add t
        end
      end
      index = TagOverviewIndex.new(site, site.source, dir, tag, alltags.to_a)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end

end
