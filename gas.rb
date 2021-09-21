#!/usr/bin/ruby
require 'rest-client'
require 'json'
@id = ARGV[0]
puts "Calculate gas for miner #{@id}"

# Convert "1,4-7,8-11" to 9
def count(sectors)
  sectors.split(',').reduce(0) do |sum, s|
    st, ed = s.split('-')
    if ed.nil?
      sum + 1
    else
      sum + ed.to_i - st.to_i + 1
    end
  end
end

def gas_usage(method = 'PreCommitSector', max = 100)
  page = 0
  result = []
  response = nil
  loop do
    loop do
#      puts "https://filfox.info/api/v1/address/#{@id}/messages?pageSize=100&page=#{page}&method=#{method}"
      response = RestClient.get("https://filfox.info/api/v1/address/#{@id}/messages?pageSize=100&page=#{page}&method=#{method}")
      break
    rescue SocketError
#      puts "Wait for 10 secs before retry fetching"
      sleep 10
      next
    end
    response = JSON.parse(response.body)
    result << response['messages']
    page += 1
    max -= response['messages'].size
    break if max <= 0 || response['messages'].size == 0
  end

  gas = 0
  count = 0
  result.flatten[0..10].each do |message|
    cid = message['cid']
    loop do
#      puts "https://filfox.info/api/v1/message/#{cid}"
      response = RestClient.get("https://filfox.info/api/v1/message/#{cid}")
      break
    rescue SocketError
#      puts "Wait for 10 secs before retry fetching"
      sleep 10
      next
    end
    response = JSON.parse(response.body)
    gas += response['transfers'].map{|transfer| transfer['to'] == 'f099' ? transfer['value'].to_i : 0}.reduce(:+)
    case method
    when 'PreCommitSector', 'ProveCommitSector'
#      puts "Contains 1 sector"
      count += 1
    when 'PreCommitSectorBatch'
#      puts "Contains #{response['decodedParams']['Sectors'].size} sector"
      count += response['decodedParams']['Sectors'].size
    when 'ProveCommitAggregate'
#      puts "Contains #{count(response['decodedParams']['SectorNumbers'])} sector"
      count += count(response['decodedParams']['SectorNumbers'])
    end
  end

  gas = gas.to_f / 1e18
  average = gas / count
  puts "For #{method}, total gas #{gas}, count #{count}, average #{average}"
end


['PreCommitSector', 'ProveCommitSector', 'PreCommitSectorBatch', 'ProveCommitAggregate'].each do |method|
  gas_usage(method)
end
