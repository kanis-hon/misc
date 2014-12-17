#!/usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'net/http'
require 'json'

class CheckRabbitMQShovel < Sensu::Plugin::Check::CLI
    option :shovel,   :short => '-s SHOVEL NAME', :required => true
    option :hostname, :short => '-h HOST NAME',   :default  => 'localhost'
    option :port,     :short => '-n PORT',        :default  => 15672
    option :protocal, :short => '-m PROTOCAL',    :default  => 'http'
    option :user,     :short => '-u USER',        :default  => 'admin'
    option :password, :short => '-p PASSWORD',    :default  => 'WilyToad1'
    
    def run
        uri=URI("#{config[:protocal]}://#{config[:hostname]}:#{config[:port]}/api/shovels")
        req = Net::HTTP::Get.new(uri)
        req.basic_auth "#{config[:user]}", "#{config[:password]}"
        
        begin
            res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
            
            obj=JSON.parse(res.body)
            exist = false
            obj.each { |o|
                if !o.is_a?(Hash)
                    critical "RabbitMQ Shovel \'#{config[:shovel]}\' status could not be retrieved.\nerror:\n#{obj}"
                end
                
                if o['name'] == config[:shovel]
                    exist = true
                    if o['state'] == 'running'
                        ok "RabbitMQ Shovel \'#{config[:shovel]}\' is running."
                        elsif o['state'] == 'blocked' or o['state'] == 'terminated'
                        critical "RabbitMQ Shovel \'#{config[:shovel]}\' has been #{o['state']}."
                        else
                        critical "RabbitMQ Shovel \'#{config[:shovel]}\' has been #{o['state']}."
                    end
                end
            }
            
            if !exist
                critical "RabbitMQ Shovel \'#{config[:shovel]}\' does not exist."
            end
            
            rescue SystemCallError, JSON::ParserError, SocketError => e
            critical "RabbitMQ Shovel \'#{config[:shovel]}\' status could not be retrieved.\nerror:\n#{e}"
        end
    end
end
