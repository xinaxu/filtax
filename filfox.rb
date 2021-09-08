require 'rest-client'
require 'json'

class FilFox
  PAGINATION = 100
  def self.get_messages(address, start_height = 0)
    get_entries("messages", address, start_height)
  end

  def self.get_transfers(address, start_height = 0)
    get_entries("transfers", address, start_height)
  end

  def self.get_blocks(address, start_height = 0)
    get_entries("blocks", address, start_height)
  end

  def self.get_entries(type, address, start_height)
    result = []
    page = 0
    loop do 
      response = nil
      loop do
        response = RestClient.get("https://filfox.info/api/v1/address/#{address}/#{type}?pageSize=#{PAGINATION}&page=#{page}")
        break
      rescue SocketError
        puts "Wait for 10 secs before retry fetching"
        sleep 10
        next
      end
      response = JSON.parse(response.body)
      result << response[type]
      page += 1
      total = response['totalCount']
      min_height = response[type].min_by{|entry| entry['height']}
      min_height = min_height.nil? ? 0 : min_height['height']
      puts "Retrieved #{type} for #{address}. Page #{page}/#{(total - 1) / PAGINATION + 1 }. Current/Target height: #{min_height}/#{start_height}"
      break if page * PAGINATION > total
      break if min_height < start_height
    end

    result.flatten(1)
  end
end

