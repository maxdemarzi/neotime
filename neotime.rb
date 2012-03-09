require 'rubygems'
require 'neography'
require 'sinatra'
require 'uri'

def generate_time(from = Time.local(2004, 1, 1), to = Time.now)
  Time.at(from + rand * (to.to_f - from.to_f)).strftime('%Y-%m-%d')
end

def time_offset(n)
    Time.local(2004, 1, 1) + ((60*60*24*58) * n)
end

def powerlaw(min=1,max=500,n=20,o=0.05)
    max += 1
    pl = ((max**(n+1) - min**(n+1))*rand() + min**(n+1))**(1.0/(n+1))
    rand > o ? (max-1-pl.to_i)+min : rand(max).to_i
end

def create_rel(from,to,start_date, end_date)
  [:create_relationship, "wrote", "{#{from}}", "{#{to}}", {:date => generate_time(start_date,end_date)}]
end

def create_graph
  neo = Neography::Rest.new
  graph_exists = neo.get_node_properties(1)
  return if graph_exists && graph_exists['name']
  commands = []
  names = %w[Aaron Achyuta Adam Adel Agam Alex Allison Amit Andreas Andrey 
             Andy Anne Barry Ben Bill Bob Brian Bruce Chris Corey 
             Dan Dave Dean Denis Eli Eric Esteban Ezl Fawad Gabriel 
             James Jason Jeff Jennifer Jim Jon Joe John Jonathan Justin 
             Kim Kiril LeRoy Lester Mark Max Maykel Michael Musannif Neil]

  commands = names.map{ |n| [:create_node, {"name" => n}]}

  names.each_index do |from|
    commands << [:add_node_to_index, "nodes_index", "type", "user", "{#{from}}"]  
    powerlaw.times do
      to = rand(50)
      commands << create_rel(from,to,time_offset([from,to].max),Time.now) 
    end
  end
  batch_result = neo.batch *commands
end

def get_parties
  neo = Neography::Rest.new
  cypher_query =  " START me = node:nodes_index(type = 'user')"
  cypher_query << " MATCH (me)-[r?:wrote]-()"
  cypher_query << " RETURN ID(me), me.name, count(r), min(r.date), max(r.date)"
  cypher_query << " ORDER BY ID(me)"
  neo.execute_query(cypher_query)["data"]
end

def get_incoming_matrix
  neo = Neography::Rest.new
  cypher_query =  " START me = node:nodes_index(type = 'user')"
  cypher_query << " MATCH (me)<-[r?:wrote]-(friends)"
  cypher_query << " RETURN ID(me), me.name, collect(ID(friends)), collect(r.date)"
  cypher_query << " ORDER BY ID(me)"
  neo.execute_query(cypher_query)["data"]
end

def get_outgoing_matrix
  neo = Neography::Rest.new
  cypher_query =  " START me = node:nodes_index(type = 'user')"
  cypher_query << " MATCH (me)-[r?:wrote]->(friends)"
  cypher_query << " RETURN ID(me), me.name, collect(ID(friends)), collect(r.date)"
  cypher_query << " ORDER BY ID(me)"
  neo.execute_query(cypher_query)["data"]
end

get '/communication' do
  p = get_parties
  parties = p.map{|p| {"id" => p[0], "name" => p[1], "value" =>p[2]} }
  cases = p.map{|p| {"title" => p[1], "initiated_at" => p[3], "last_correspondance_at" =>p[4], "exchanges" => []} }
  
  gim = get_incoming_matrix
  gim.each_index do |im|
    sors = gim[im][2][1..(gim[im][2].size - 2)].split(", ")
    jds  = gim[im][3][1..(gim[im][3].size - 2)].split(", ")
    sors.size.times do |t|
      cases[im]["exchanges"] <<  {"incoming" => true, "sender_or_recipent" => sors[t], "journal_date" => jds[t]}  
    end
  end

  gom = get_outgoing_matrix
  gom.each_index do |om|
    sors = gom[om][2][1..(gom[om][2].size - 2)].split(", ")
    jds  = gom[om][3][1..(gom[om][3].size - 2)].split(", ")
    sors.size.times do |t|
      cases[om]["exchanges"] <<  {"incoming" => false, "sender_or_recipent" => sors[t], "journal_date" => jds[t]}  
    end
  end
  {:cases => cases, :parties => parties}.to_json
end
