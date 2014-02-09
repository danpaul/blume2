#need to search for all src as well as href for links
#look for links as well (should be searching for hrefs and src)

#clean up abs url

#"assets" is file path

#auto detect assets and download them automatically

class Pilgrim
	def initialize(root_url, site_directory, assets, target_url = false)

@asset_folders = ['/css', '/js', '/img', '/audio']
@source_directory = '/Users/danielbreczinski/Desktop/working_code/dpb_me'
# assets = 'assets'
# @target_url = 'http://dpb.me'
# @target_url = 'localhost:8888/site'
@target_url = 'http://localhost:8888/site'
# @target_url = false
@base_url = 'http://localhost:4567'
@asset_urls = [];

#@asset_folders.each{|a| @asset_urls <<  @base_url + '/assets'}


		@root_url = root_url
		@site_directory = site_directory
		@assets = assets
		# @target_url = target_url
		# @asset_folders = Dir.glob(@assets).
		# 	reject{|f| not File.directory?(f)}.
		# 	map{|d| "/" + d + "/"}

		@asset_folders.each do |folder|
			@asset_urls << absolute_url(@base_url, folder)
		end
# puts 'foo'
# puts @asset_urls
	end

	def generate(compression_on = true)

# puts @assets;

		visited = Set.new
		unvisited = Set.new [@root_url]
		FileUtils.rm_rf(@site_directory)
		while !unvisited.empty?
			parse_page(visited, unvisited)
		end

		# @asset_folders.each do |folder|
		# 	FileUtils.mkdir(@site_directory + folder)
		# 	FileUtils.cp_r(Dir[@source_directory + '/public' + folder], @site_directory)
		# end


		if compression_on then compress end
	end
	def parse_page(visited, unvisited)

		current = unvisited.take(1)
		visited << current[0]
		page = Nokogiri::HTML(open(current[0]))

		page.css('[href]').each do |link|
			absolute_link = absolute_url(@base_url, link['href']);
			if in_domain(absolute_link)


# puts File.extname(URI.parse(absolute_link).path)

				if is_css absolute_link
					copy_from_url(absolute_link)
					#copy file
					#add to vis

				else
					unless visited.include? absolute_link
						unvisited << absolute_link
					end
				end



				# unless is_asset(absolute_url(@base_url, link['href']))
				# 	unless visited.include? absolute_link
				# 		unvisited << absolute_link
				# 	end
				# end
				link['href'] = absolute_link.sub(@root_url, @target_url);
			end
		end


		page.css('[src]').each do |link|
			absolute_src = absolute_url(@base_url, link['src'])
			if in_domain(absolute_src)
				copy_from_url(absolute_src)

# 				dest_path = @site_directory + (get_root_relative_path absolute_src)
# 				unless File.exists? dest_path


# dirname = File.dirname(dest_path)
# puts dirname
# unless File.directory?(dirname)
#   FileUtils.mkdir_p(dirname)
# end

# open(dest_path, 'wb') do |file|
#   file << open(absolute_src).read
# end
					
# 				end

				link['src'] = absolute_src.sub(@root_url, @target_url);
			end
		end



		# page.css('[src]').each do |link|
		# 	absolute_src = absolute_url(@base_url, link['src']);
		# 	if in_domain(absolute_src)
		# 		link['src'] = absolute_src.sub(@root_url, @target_url);
		# 	end
		# end

		save_file(page, current)
		unvisited.subtract(current)
	end



	def copy_from_url(url)
		dest_path = @site_directory + get_root_relative_path(url)
		unless File.exists? dest_path
			# absolute_src = absolute_url(@base_url, link['src']);
			dirname = File.dirname(dest_path)
			unless File.directory?(dirname)
			  FileUtils.mkdir_p(dirname)
			end
			open(dest_path, 'wb') do |file|
			  file << open(url).read
			end
		end
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

	def in_domain(url)
		if url.start_with?(@base_url)
			return true
		end
		return false
	end

	def is_css(url)
		return File.extname(URI.parse(url).path).downcase == '.css'
	end

	def save_file(page, file)
		path = @site_directory + file[0].sub(@root_url, "/")
		FileUtils.mkpath(path)
		File.open(path + "/index.html", "w"){|f| f.write(page.to_html)}
	end

	def get_root_relative_path(absolute_url)
		return absolute_url.sub(@root_url, '')
	end

	def absolute_url(base, url)
		URI.join(base, url).to_s
	end




end