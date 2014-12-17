require 'logger'
require 'pp'

$logger = Logger.new('logfile.log')
$logger.level = Logger::DEBUG
$logger.formatter = proc do |s, d, progname, msg|
   "tag_overview_gen: #{d}: #{msg}\n"
end

module Jekyll

  class TagJson < Page
    def initialize(site, dir, layout_name, target_file, tag, data)
      $logger.debug("TagJson:: layout=#{layout_name} for #{target_file}")
      @site = site
      @base = site.source
      @dir = dir
      @name = target_file

      self.process(@name)
      self.read_yaml(File.join(@base, '_layouts'), "#{layout_name}.json")
      self.data['tag'] = tag
      self.data['title'] = "Tags"
      unless data.nil?
        self.data[data[0]] = data[1] # for additional data
        $logger.debug "--> TagJson with [#{data[0]}]"
      end
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
        tag_weights = p.data['tag_weights']
        if p.tags.length != tag_weights.length
          raise "tags have to be matched with tag_weight (wrong for #{p.title})"
        end
        dest = site.config['destination']
        d = p.destination(dest)
        d["#{dest}/"] = ''
        d["/index.html"] = ''
        tags_with_ratio = {}
        p.tags.each_with_index { |t,i|
          tags_with_ratio[t] = tag_weights[i]
        }
        write_tag_ratio_json(site, d, ["tagratio",tags_with_ratio])
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
        write_tag_index(site, 'tag', "all_tags", 'tag_list', 'tags.json', ["alltags",sorted])
      end
      if site.layouts.key? 'tag_deps'
        write_tag_index(site, 'tag', "tag_dependencies", 'tag_deps', 'dependencies.json', ["tagmapping",tag_map_with_list])
      end
    end

    def write_tag_ratio_json(site, dir, data)
      json = TagJson.new(site, dir, 'tag_ratio', 'tag_ratio.json', nil, data)
      json.render(site.layouts, site.site_payload)
      json.write(site.dest)
      site.pages << json
    end
    def write_tag_index(site, dir, tag, layout_name, target_file, data)
      json = TagJson.new(site, dir, layout_name, target_file, tag, data)
      json.render(site.layouts, site.site_payload)
      json.write(site.dest)
      site.pages << json
    end
  end

end

