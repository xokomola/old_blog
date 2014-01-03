module Jekyll
 
  class TagFeed < Page    
    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = 'atom.xml'
 
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'atom.xml')
      self.data['tag'] = tag
      self.data['title'] = "Posts Tagged &ldquo;"+tag+"&rdquo;"
    end
  end
 
  class FeedGenerator < Generator
    safe true
    
    def generate(site)
      if site.layouts.key? 'atom'
        dir = 'tags'
        site.tags.keys.each do |tag|
          write_tag_feed(site, File.join(dir, tag), tag)
        end
      end
    end
  
    def write_tag_feed(site, dir, tag)
      index = TagFeed.new(site, site.source, dir, tag)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end
 
end