#need to search for all src as well as href for links

#clean up abs url

#"assets" is file path
class Pilgrim
	def initialize(root_url, site_directory, assets, target_url = false)


@asset_folders = ['css', 'js', 'img', 'audio']

# assets = 'assets'
# @target_url = 'http://dpb.me'
# @target_url = 'localhost:8888/site'
@target_url = 'http://localhost:8888/site'
# @target_url = false
@base_url = 'http://localhost:4567'
@asset_urls = [];

@asset_folders.each{|a| @asset_urls <<  @base_url + '/assets'}


		@root_url = root_url
		@site_directory = site_directory
		@assets = assets
		# @target_url = target_url
		@asset_folders = Dir.glob(@assets).
			reject{|f| not File.directory?(f)}.
			map{|d| "/" + d + "/"}
	end

	def generate(compression_on = true)
		visited = Set.new
		unvisited = Set.new [@root_url]
		FileUtils.rm_rf(@site_directory)
		while !unvisited.empty?
			parse_page(visited, unvisited)
		end
		# FileUtils.cp_r(Dir[@assets + "/*"], @site_directory)
		FileUtils.cp_r(Dir[@assets], @site_directory)
		if compression_on then compress end
	end
	def parse_page(visited, unvisited)

# puts 'asdf'

		current = unvisited.take(1)
		visited << current[0]
		page = Nokogiri::HTML(open(current[0]))
		page.css('a').each do |link|


# puts absolute_url(@base_url, link['href'])
# puts @asset_base_url

			# is_an_asset = @asset_folders.any?{|d| link['href'].start_with? d}
			# is_an_asset = absolute_url(@base_url, link['href']).start_with?(@base_url)
			is_an_asset = is_asset(absolute_url(@base_url, link['href']))


if(is_an_asset)
	puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
end
			# @asset_folders.any?{|d| link['href'].start_with? d}


# if is_an_asset
# 	puts link[]
# # 	puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
# # 	exit()
# end


			if link['href'].start_with? "/"
				unless visited.include? @root_url + link['href'] or is_an_asset
					unvisited << @root_url + link['href']
				end
				if @target_url
					link['href'] = @target_url + link['href']
					link['href'] = URI.join(@target_url, link['href'])
				end
			end
		end

		save_file(page, current)
		unvisited.subtract(current)
	end


	def compress()
		Find.find(@site_directory) do |f_name|
			ext = File.extname(f_name).downcase
			if ext == '.htm' || ext == '.html' || ext == '.js' || ext == '.css'
				File.open(f_name,'rb') do |f|
					File.open(f_name + ".gz", 'w') do |gz_f|
						gz = Zlib::GzipWriter.new(gz_f)
						gz.write(f.read)
						gz.close
					end
				end
			end
		end
	end

	def is_asset(url)
		@asset_urls.each do |asset_url|
			if url.start_with?(asset_url) 
				return true
			end
		end
		return false
	end





	def save_file(page, file)
		path = @site_directory + file[0].sub(@root_url, "/")
		FileUtils.mkpath(path)
		File.open(path + "/index.html", "w"){|f| f.write(page.to_html)}
	end

	def absolute_url(base, url)
		URI.join(base, url).to_s
	end




end