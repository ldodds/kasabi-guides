require 'rubygems'
require 'linkeddata'
require 'kasabi'
require 'json'

client = Kasabi::Sparql::Client.new( ARGV[0], :apikey => ENV["KASABI_API_KEY"] )  

config = {
  "endpoint" => ARGV[0]
}

types = Kasabi::Sparql::SparqlHelper.select_values("SELECT DISTINCT ?type WHERE {?s a ?type.}", client)

config["types"] = {}
  
types.each do |type|
  config["types"][type] = type
end

puts JSON.pretty_generate(config)
