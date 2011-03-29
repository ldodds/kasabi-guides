require 'rubygems'
require 'linkeddata'
require 'json'
require 'kasabi'
require 'erb'

def suffix(uri)
  candidate_suffix = uri.split("/").last
  if candidate_suffix.index("#") != -1
    return candidate_suffix.split("#").last
  end
  return candidate_suffix      
end

def readable_suffix(uri)
  readable = suffix(uri).split(/(?=[A-Z])/).join(' ')
  return readable.split(" ").map { |word| word.capitalize }.join(" ")
end

def get_example(client, type)
  response = client.describe( "DESCRIBE ?s WHERE { ?s a <#{type}>} LIMIT 1", "application/json" )
  if response.status != 200
    $stderr.puts "Unable to describe #{type}"
    $stderr.puts response.content
    return nil
  end
  graph = RDF::Repository.new
  RDF::Reader.for(:json).new( StringIO.new(response.content) ) do |reader|
    graph.insert( reader.statements )
  end  
  return graph
end

def sample_properties(client, type, prefixes, number=5)
  response = client.describe( "DESCRIBE ?s WHERE { ?s a <#{type}>} LIMIT #{number}", "application/json" )
  if response.status != 200
    $stderr.puts "Unable to sample #{type}"
    $stderr.puts response.content
    return nil
  end
  graph = RDF::Repository.new
  RDF::Reader.for(:json).new( StringIO.new(response.content) ) do |reader|
    graph.insert( reader.statements )
  end
  properties = {}  
  RDF::Writer.for(:turtle).buffer( :prefixes => prefixes ) do |writer|
    graph.each_statement do |statement|
      if statement.predicate != RDF.type
        qname = writer.get_qname( statement.predicate.to_s )
        if qname != nil
          properties[ readable_suffix(statement.predicate.to_s) ] = writer.get_qname( statement.predicate.to_s ).join(":")
        else
          properties[ readable_suffix(statement.predicate.to_s) ] = statement.predicate.to_s
        end
      end
    end
  end
  return properties
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

template = ERB.new(File.read( ARGV[1] ) )
    
client = Kasabi::Sparql::Client.new( config["endpoint"], :apikey => ENV["KASABI_API_KEY"] )  

results = {}
  
config["types"].each_pair do |name, type|
  
  graph = get_example(client, type)

  properties = sample_properties(client, type, PREFIXES)
  
  results[name] = {}
    
  example = RDF::Writer.for(:turtle).buffer( :prefixes => PREFIXES ) do |writer|
    results[name]["qname"] = writer.get_qname(type)
    graph.each_statement do |statement|
      writer << statement
    end
  end
  
  results[name]["example"] = example
  results[name]["properties"] = properties
    
end

#TODO
#filter prefixes to just those encountered?
#add names for vocabs
#uri templates?
#encountered properties
b = binding 
config = config   
results = results
prefixes = PREFIXES
puts template.result(b)
