require 'logger'
require 'pp'

$logger = Logger.new('logfile.log')
$logger.level = Logger::DEBUG
$logger.formatter = proc do |s, d, progname, msg|
   "tag_overview_gen: #{d}: #{msg}\n"
end

module Jekyll

  class TagJson < Page
    def initialize(site, dir, layout_name, target_file, tag, sorted_tags, tag_map)
      $logger.debug("TagJson:: tag=#{tag}")
      @site = site
      @base = site.source
      @dir = dir
      @name = target_file

      self.process(@name)
      self.read_yaml(File.join(@base, '_layouts'), "#{layout_name}.json")
      self.data['tag'] = tag
      self.data['title'] = "Tags"
      self.data['alltags'] = sorted_tags
      self.data['tagmapping'] = tag_map
      self.data['type'] = "tag_type"
    end
  end

  class TagJsonGenerator < Generator
    safe true

    def categorize(tag)
      categories = {
        # languages
        "C++" => "languages",
        "haskell" => "languages",
        "ruby" => "languages",
        "lua" => "languages",
        "ghc" => "languages",
        "llvm" => "languages",
        "clang" => "languages",
        "templates" => "languages",
        # cs
        "algorithm" => "cs",
        "performance" => "cs",
        "datastructure" => "cs",
        "networking" => "cs",
        "udp" => "cs",
        "concurrency" => "cs",
        "types" => "cs",
        # unix
        "bash" => "unix",
        "unix" => "unix",
        "rake" => "unix",
        "tool" => "unix",
        "git" => "unix",
        # testing
        "testing" => "testing",
        "gtest" => "testing",
        "quickcheck" => "testing",
        # techniques
        "dsl" => "techniques",
        # fun
        "blogging" => "fun",
        "rant" => "fun",
        "puzzle" => "fun",
        # os
        "osx" => "os",
        "android" => "os",
        "ipc" => "os"
      }
      if categories[tag].nil?
        "unknown.#{tag}"
      else
        "#{categories[tag]}.#{tag}"
      end

    end

    def generate(site)
      $logger.debug "TagJsonGenerator:: generator running, site: #{site}"
      alltags = []
      tag_map = {}
      site.posts.each do |p|
        p.tags.each do |t|
          alltags << t
          ct = categorize(t)
          peers = p.tags.collect {|t| categorize t} - [ct]
          if tag_map[ct].nil?
            tag_map[ct] = Set.new(peers)
          else
            peers.each { |p| tag_map[ct] << p }
          end
        end
      end
      tag_map_with_list = {}
      tag_map.each do |k,v|
        tag_map_with_list[k] = v.to_a
      end
      counts = Hash.new(0)
      alltags.each do |t|
        counts[t] += 1
      end
      sorted = counts.sort { |a,b| b[1] <=> a[1] }

      $logger.debug "available layouts: #{site.layouts.keys}"
      if site.layouts.key? 'tag_list'
        write_tag_index(site, 'tag', "all_tags", 'tag_list', 'tags.json', sorted, tag_map_with_list)
      end
      if site.layouts.key? 'tag_deps'
        write_tag_index(site, 'tag', "tag_dependencies", 'tag_deps', 'dependencies.json', sorted, tag_map_with_list)
      end
    end

    def write_tag_index(site, dir, tag, layout_name, target_file, tags_sorted, tag_map)
      json = TagJson.new(site, dir, layout_name, target_file, tag, tags_sorted, tag_map)
      json.render(site.layouts, site.site_payload)
      json.write(site.dest)
      site.pages << json
    end
  end

end

