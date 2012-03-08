require 'rubygems'
require 'neography'
require 'sinatra'
require 'uri'

def generate_time(from = Time.local(2000, 1, 1), to = Time.now)
  Time.at(from + rand * (to.to_f - from.to_f)).strftime('%Y-%m-%d')
end

def powerlaw(min=1,max=500,n=10)
    max += 1
    pl = ((max**(n+1) - min**(n+1))*rand() + min**(n+1))**(1.0/(n+1))
    (max-1-pl.to_i)+min
end

def create_rel(from,to,start_date,end_date)
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

#  commands = names.map{ |n| [:create_node, {"name" => n}]}

  names.each do |n| 
    t = 10.times.collect{|x|generate_time}
    commands << [:create_node, {:name => n, 
                                :joined_at => t.min, 
                                :last_seen_at => t.max}]
  end
      
  
  names.each_index do |from|
    commands << [:add_node_to_index, "nodes_index", "type", "user", "{#{from}}"]  
    powerlaw.times do
      to = rand(50)
      commands << create_rel(from,to, 
                             [Time.local(commands[to][1][:joined_at]),Time.local(commands[from][1][:joined_at])].max, 
                             [Time.local(commands[to][1][:last_seen_at]), Time.local(commands[from][1][:last_seen_at])].min 
                             ) unless (Time.local(commands[to][1][:joined_at]) > Time.local(commands[from][1][:last_seen_at]) ||
                                       Time.local(commands[from][1][:joined_at]) > Time.local(commands[to][1][:last_seen_at]) ) 
    end
  end
  batch_result = neo.batch *commands
end

def get_parties
  neo = Neography::Rest.new
  cypher_query =  " START me = node:nodes_index(type = 'user')"
  cypher_query << " MATCH (me)-[r?:wrote]-()"
  cypher_query << " RETURN ID(me), me.name, count(r), min(r.date), max(r.date)"
  neo.execute_query(cypher_query)["data"]
end


def get_incomming_matrix
  neo = Neography::Rest.new
  cypher_query =  " START me = node:nodes_index(type = 'user')"
  cypher_query << " MATCH (me)<-[r?:wrote]-(friends)"
  cypher_query << " RETURN ID(me), me.name, r.date, ID(friends)"
  neo.execute_query(cypher_query)["data"]
end

def get_outgoing_matrix
  neo = Neography::Rest.new
  cypher_query =  " START me = node:nodes_index(type = 'user')"
  cypher_query << " MATCH (me)-[r?:wrote]->(friends)"
  cypher_query << " RETURN ID(me), me.name, r.date, ID(friends)"
  neo.execute_query(cypher_query)["data"]
end


get '/communication' do
require 'net-http-spy'
# Net::HTTP.http_logger_options = {:body => true}    # just the body
Net::HTTP.http_logger_options = {:verbose => true} # see everything
  p = get_parties
  parties = p.map{|p| {"id" => p[0], "name" => p[1], "value" =>p[4]} }
  p.to_json
  
  #i = get_incomming_matrix
  #i.to_json
#  communication_matrix.map{|cm| {"name" => fm[0], "follows" => fm[1][1..(fm[1].size - 2)].split(", ")} }.to_json
end
