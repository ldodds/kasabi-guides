require 'rubygems'
require 'linkeddata'
require 'json'
require 'kasabi'

def get_example(client, type)
  response = client.describe( "DESCRIBE ?s WHERE { ?s a <#{type}>} LIMIT 1", "application/json" )
  if response.status != 200
    puts "Unable to describe #{type}"
    puts response.content
    return nil
  end
  graph = RDF::Repository.new
  RDF::Reader.for(:json).new( StringIO.new(response.content) ) do |reader|
    graph.insert( reader.statements )
  end  
  return graph
end

PREFIXES = {
  "owl" => "http://www.w3.org/2002/07/owl#",
  "foaf" => "http://xmlns.com/foaf/0.1/",
  "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
  "skos" => "http://www.w3.org/2004/02/skos/core#",
  "dct" => "http://purl.org/dc/terms/"
}

config = JSON.parse( File.open( ARGV[0], "r" ).read )

PREFIXES.merge!( config["prefixes"] )
  
client = Kasabi::Sparql::Client.new( config["endpoint"], :apikey => ENV["KASABI_API_KEY"] )  

config["types"].each_pair do |name, type|
  graph = get_example(client, type)
  puts "#EXAMPLE RESOURCE OF TYPE #{type}"
  data = RDF::Writer.for(:turtle).buffer( :prefixes => PREFIXES ) do |writer|
    graph.each_statement do |statement|
      writer << statement
    end
  end
  puts data
  puts "#--------------------------------"
end
