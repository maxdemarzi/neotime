require 'rubygems'
require 'neography'
require 'sinatra'
require 'uri'

require 'net-http-spy'
# Net::HTTP.http_logger_options = {:body => true}    # just the body
Net::HTTP.http_logger_options = {:verbose => true} # see everything

def generate_text(length = 8)
  chars = 'abcdefghjkmnpqrstuvwxyz'
  key = ''
  length.times { |i| key << chars[rand(chars.length)] }
  key
end


def generate_time(from = Time.local(2000, 1, 1), to = Time.now)
  Time.at(from + rand * (to.to_f - from.to_f)).strftime('%Y-%m-%d')
end

def create_rel(x,y)
  [:create_relationship, "wrote", "{#{x}}", "{#{y}}", {:date => generate_time}]
end

def create_graph
  neo = Neography::Rest.new
  graph_exists = neo.get_node_properties(1)
  return if graph_exists && graph_exists['name']
  commands = []
  
  names = 100.times.collect{|x| generate_text}
  commands = names.map{ |n| [:create_node, {"name" => n}]}
  
  names.each_index do |x| 
    wrote = names.size.times.map{|y| y}
    wrote.sample(rand(500)).each do |y|
      commands << create_rel(x,y)    
    end
  end
  batch_result = neo.batch *commands
end
