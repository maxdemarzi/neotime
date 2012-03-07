require 'rubygems'
require 'neography'
require 'sinatra'
require 'uri'

#require 'net-http-spy'
# Net::HTTP.http_logger_options = {:body => true}    # just the body
#Net::HTTP.http_logger_options = {:verbose => true} # see everything

def generate_text(length = 8)
  chars = 'abcdefghjkmnpqrstuvwxyz'
  key = ''
  length.times { |i| key << chars[rand(chars.length)] }
  key
end


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
  names = []
  50.times do 
    t = 10.times.collect{|x|generate_time}
    names << {:name => generate_text, 
              :joined_at => t.min, 
              :last_seen_at => t.max}
  end
      
  commands = names.map{ |n| [:create_node, n]}
  
  names.each_index do |from| 
    powerlaw.times do
      to = rand(50)
      commands << create_rel(from,to, 
                             [Time.local(names[to][:joined_at]),Time.local(names[from][:joined_at])].max, 
                             [Time.local(names[to][:last_seen_at]), Time.local(names[from][:last_seen_at])].min 
                             ) unless (Time.local(names[to][:joined_at]) > Time.local(names[from][:last_seen_at]) ||
                                       Time.local(names[from][:joined_at]) > Time.local(names[to][:last_seen_at]) ) 
    end
  end
  batch_result = neo.batch *commands
end
