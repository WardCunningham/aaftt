require 'rubygems'
require 'csv'
require 'json'
require 'pp'

# wiki utilities

def random
  (1..16).collect {(rand*16).floor.to_s(16)}.join ''
end

def slug title
  title.gsub(/\s/, '-').gsub(/[^A-Za-z0-9-]/, '').downcase()
end

def clean text
  text.gsub(/’/,"'")
end

def url text
  text.gsub(/(http:\/\/)?([a-zA-Z0-9._-]+?\.(net|com|org|edu)(\/[^ )]+)?)/,'[http:\/\/\2 \2]')
end

def domain text
  text.gsub(/((https?:\/\/)(www\.)?([a-zA-Z0-9._-]+?\.(net|com|org|edu|us|cn|dk|au))(\/[^ );]*)?)/,'[\1 \4]')
end

# journal actions

def create title
  @journal << {'type' => 'create', 'id' => random, 'item' => {'title' => title}, 'date' => Time.now.to_i*1000}
end

def add item
  @story << item
  @journal << {'type' => 'add', 'id' => item['id'], 'item' => item, 'date' => Time.now.to_i*1000}
end

# story emiters

def paragraph text
  add({'type' => 'paragraph', 'text' => text, 'id' => random()})
end

def page title
  @story = []
  @journal = []
  create title
  yield
  page = {'title' => title, 'story' => @story, 'journal' => @journal}
  File.open("../pages/#{slug(title)}", 'w') do |file|
    file.write JSON.pretty_generate(page)
  end
end

# spreadsheet data

csv = CSV.read "tool-features.csv"

name = csv.shift
site = csv.shift
goal = csv.shift

role = 0
capability = 1
details = 2
tools = 3..name.length-1

roles = csv.collect {|row| row[role]}.uniq

# generate pages

page 'Functional Testing Tools' do
  paragraph "We extract wiki pages from the rediscovered testing tool spreadsheet."
  paragraph "See also the [[Glossary of Terms]] used defining capabilities."
  tools.each do |tool|
    synopsis = goal[tool].split('. ')[0]
    paragraph "[[#{name[tool]}]] — #{synopsis}"
  end
end

glossary = {}
csv.each do |row|
  next unless row[capability] and row[details]
  glossary[row[capability]] = row[details]
end
page 'Glossary of Terms' do
  paragraph "Some of the terms used in the index deserve further definition. We don't link these in the tool descriptions because we think all the links would be distracting."
  glossary.keys.sort.each do |key|
    paragraph "<b>#{key}</b> — #{glossary[key]}"
  end
end

tools.each do |tool|
  puts name[tool]
  page name[tool] do
    paragraph goal[tool]
    paragraph url site[tool] if site[tool]
    roles.each do |section|
      paragraph "<h3> #{section}"
      csv.each do |row|
        next unless row[role] == section
        next unless row[capability]
        paragraph url "#{row[capability]}: #{row[tool]}" if row[tool]
      end
    end
  end
end