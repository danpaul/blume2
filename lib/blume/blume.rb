class Blume
	attr_reader :content
	def initialize(options_in = {})
		options = {
			content_directory: File.join(Dir.pwd, 'content'),
			living_dangerously: true,
			root_url: 'http://localhost:4567',
			site_directory: File.join(Dir.pwd, 'site'),
			assets: File.join(Dir.pwd, 'public')
             }.merge(options_in)
        @content = {}
		@content_directory = options[:content_directory]
		@living_dangerously = options[:living_dangerously]
		@pilgrim = Pilgrim.new(options[:root_url], options[:site_directory], options[:assets])
	end

	def build_content()
		@content = {}
		walk @content_directory
		@content.each do |k, v|
			v.sort!{|a,b| b['date_title'] <=> a['date_title']}
		end
		return @content
	end

	def get_tags(type)
		tags = []
		@content[type].each do |post|
			post['tags'].each do |t|
				tags.push(t) unless tags.include?(t)
			end
		end
		tags.sort!{|a,b| a <=> b}
		return tags
	end

	def get_posts_with_tag(tag)
		get_listings_with_tag('posts', tag)
	end

	def get_listings_with_tag(type, tag)
		@content[type].map{|post| post if(post['tags'].include?(tag))}.compact
	end

	def generate_site(compress = true)
		@pilgrim.generate(compress)
	end

	def walk(path)
		Dir.foreach(path) do |f|
			unless f[0] == '.'
				file = File.join(path, f)
				if File.directory?(file)
					walk file
				else
					post = parse(file, path)
					if(!@content.has_key?(post['type'])) then @content[post['type']] = [] end
					@content[post['type']].push(post)						
				end
			end
		end
	end

	def parse(file, path)
		post = YAML.load_file(file)
		post['type'] = path.sub(@content_directory,'').gsub(/\//, '-')[1..-1]
		# post['title'] = File.basename(file,File.extname(file))[11..-1]
		post['title'] = File.basename(file,File.extname(file))[11..-1].gsub('-', ' ')
		post['date_time'] = Date.parse(File.basename(file, File.extname(file))[0..11]).to_time
		post['date_title'] = post['date_time'].strftime("%Y-%m-%d") + '-' + (post['title'].gsub(' ', '-').downcase)
		body = ""
		if @living_dangerously
			body = evil_mark(File.open(file,'rb').read.sub(/\-\-\-.*\-\-\-/m,'').lstrip)
		else
			body = File.open(file,'rb').read.sub(/\-\-\-.*\-\-\-/m,'').lstrip
		end
		post['body'] = RedCloth.new(body).to_html
		return post
	end

	def evil_mark text
		part = text.partition(/[^\\]\#{.*?}/)
		return_string = part[0]
		until part[1] == ""
			return_string << eval("\"" + part[1] + "\"")
			part = evil_mark(part[2]).partition(/[^\\]\#{.*?}/)
			return_string << part[0]
		end
		return_string.gsub!(/\\\#{.*?}/){|s| s[1..-1]}
		return return_string
	end
end
