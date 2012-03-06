require 'rubygems'
require 'neography'
require 'sinatra'
require 'uri'

require 'net-http-spy'
# Net::HTTP.http_logger_options = {:body => true}    # just the body
Net::HTTP.http_logger_options = {:verbose => true} # see everything

def generate_text(length=8)
  chars = 'abcdefghjkmnpqrstuvwxyz'
  key = ''
  length.times { |i| key << chars[rand(chars.length)] }
  key
end

def create_rel(x,y,z)
  [:create_relationship, "knows", "{#{x}}", "{#{y}}", {:weight => z}]
end

def create_graph
  neo = Neography::Rest.new
  graph_exists = neo.get_node_properties(1)
  return if graph_exists && graph_exists['name']
  commands = []
  
  batch_result = neo.batch *commands
end
