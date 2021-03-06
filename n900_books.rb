#!/usr/bin/env ruby
# Bilal Hussain

# Use calibre exported data to fill in the series info in FBReader sqlite database
# Made for FBReader on N900

require "rubygems"
require 'xml'
require 'sqlite3'

Dir.chdir  File.expand_path("~/books/")
BooksDB = File.expand_path("~/books.db")
OpfGlob = "*.opf"

# Returns the series, series_num and title of the opf
def opf_parse(opf_file)
	puts "Parsing #{opf_file}"
	File.open(opf_file) do |file|
		opf  = XML::Parser.io(file).parse
		meta = opf.root.children[1]

		series = series_num = title = nil
		series_res     = meta.find("//opf:meta[@name='calibre:series']/@content")
		series         = series_res[0].value if series_res.length > 0

		series_num_res = meta.find("//opf:meta[@name='calibre:series_index']/@content")
		series_num     = series_num_res[0].value if series_num_res.length > 0

		title_res      = meta.find("//dc:title/text()")
		title          = title_res[0] if series_num_res.length > 0 
		puts "Series: #{series} series_num: #{series_num} title: #{title}"
		return series, series_num, title
	end
	
	
end

def add_series(db, series, series_num, title)
	query = <<-SQL
	Select b.title, s.name, bs.series_id, b.book_id
	From Books b
	Left Join BookSeries bs on b.book_id=bs.book_id
	Left Join Series s on bs.series_id= s.series_id
	Where b.title = "#{title}" 
	SQL
	
	check = db.execute( query )
	($stderr.puts "error: book not found"; return ) unless check.length > 0
	book_id = check[0]['book_id']
	
	($stderr.puts "error: No book id"; return )  unless book_id 
	puts "Book_id #{book_id}"
	
	if check[0]['name'] == nil
		
		puts check[0]['title']
		s_exists =db.execute("Select * From Series Where name = \"#{series}\" ")
		
		# Gets/makes the series id 
		series_id = 
		if s_exists.length == 0 then
			db.execute("Insert Into Series(name) Values(\"#{series}\") ")
			db.execute("Select series_id From Series Where name = \"#{series}\" ")[0]['series_id']
		else 
			s_exists[0]['series_id']
		end
		
		db.execute(
			"Insert Into BookSeries(book_id,series_id,book_index) 
			 Values(#{book_id}, #{series_id}, #{series_num})"
		)
		puts "added #{title} to the series #{series} at index #{series_num}"
	end
	
end

db = SQLite3::Database.new( BooksDB )
db.results_as_hash = true;

Dir.glob(OpfGlob).each do |opf_file|
	puts
	series, series_num, title = opf_parse(opf_file)
	next if (series.nil? or series_num.nil? or title.nil?)
	add_series(db,series, series_num, title )
end


