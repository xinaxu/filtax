#!/usr/bin/ruby
require 'slop'
require 'rest-client'
require 'json'
require 'set'
require 'nokogiri'
require 'open-uri'

opts = Slop::Options.new
opts.banner = "Usage: ./filtax.rb [options]"
opts.array '-a', '--address', 'Wallet or miner address'
opts.on '-h', '--help', 'print help' do
  puts opts
  exit
end
parser = Slop::Parser.new(opts)
begin
  options = parser.parse(ARGV)
rescue
  puts opts
  exit
end

exchanges = ["f13sb4pa34qzf35txnan4fqjfkwwqgldz6ekh5trq"]

def get_type(address)
  if File.exists?("cache.json")
    cache = JSON.parse(File.read("cache.json"))
  else 
    cache = {}
  end
  if cache.has_key? address
    return cache[address]
  end

  puts "Querying #{address}"
  doc = Nokogiri::HTML(URI.open("https://filfox.info/en/address/#{address}"))
  if doc.css('.mr-4').any?{|c| c.content.include? "Payment Channel"}
    result = 'payment'
    cache[address] = result
  elsif doc.css('.mt-4').any?{|c| c.content.include? "Adjusted Power"}
    result = 'miner'
    cache[address] = result
  elsif doc.css('.mr-4').any?{|c| c.content.include? "Account"}
    result = 'account'
    cache[address] = result
  end

  File.write("cache.json", JSON.generate(cache))
  return result
end

def get_messages(address, type)
  if File.exists?("#{address}.#{type}.json")
    result = JSON.parse(File.read("#{address}.#{type}.json"))
  else 
    result = {}
  end

  initial_size = result.size

  puts "Retrieving #{type} for address #{address}"
  page = 0
  loop do
    break_outer = false
    puts "  Page #{page}"
    # The pagination should be relatively reliable. Even if the chain is updated during the retrieval, it should not cause data missing or duplication
    response = JSON.parse(RestClient.get("https://filfox.info/api/v1/address/#{address}/#{type}?pageSize=100&page=#{page}").body)
    break if response[type].nil? || response[type].length == 0
    response[type].each do |transfer|
      case type
      when 'transfers'
        # message_id + type seems to be unique globally
        next if transfer['type'] == 'reward'
        if transfer['message'].nil? && transfer['type'] == 'burn'
          key = transfer['timestamp']
        else
          p transfer if transfer['message'].nil?
          key = transfer['message'] + '-' + transfer['type']
        end
        if result.has_key? key
          break_outer = true
          break
        end
        result[key] = [transfer['from'], transfer['to'], transfer['type'], transfer['value'].to_i, transfer['timestamp']]
      when 'blocks'
        key = transfer['cid']
        if result.has_key? key
          break_outer = true
          break
        end
        result[key] = [transfer['reward'].to_i, transfer['timestamp']]
      end
    end
    break if break_outer
    page += 1
  end

  if result.size > initial_size
    File.write("#{address}.#{type}.json", JSON.generate(result))
  end

  result
end

addresses = Set.new(options[:address])

exceptions = []
burn_fees = []
miner_fees = []
deal_fees = []
exec_fees = []
payments = []
rewards = []
addresses.each do |address|
  get_messages(address, "transfers").values.each do |from, to, type, value, timestamp|
    case type
    when 'burn-fee','burn'
      burn_fees.push([timestamp, -value])
    when 'miner-fee'
      miner_fees.push([timestamp, -value])
    when 'transfer','send','receive'
      if addresses.include?(from) && addresses.include?(to)
        next
      elsif to == 'f05'
        deal_fees.push([timestamp, -value])
      elsif to == 'f01'
        exec_fees.push([timestamp, -value])
      elsif type == 'send' && get_type(to) == 'payment'
        payments.push([timestamp, -value])
      else
        exceptions.push([from, to, type, value, timestamp])
      end
    else
      exceptions.push([from, to, type, value, timestamp])
    end
  end
  get_messages(address, "blocks").values.each do |value, timestamp|
    rewards.push([timestamp, value])
  end
end

puts "Summary"
puts "  Burn Fees : %0.2f Fil" % [(burn_fees.reduce(0){|sum, x| sum += x[1]}/1000000000000000000.0).to_s]
puts "  Miner Fees: %0.2f Fil" % [(miner_fees.reduce(0){|sum, x| sum += x[1]}/1000000000000000000.0).to_s]
puts "  Deal Fees : %0.2f Fil" % [(deal_fees.reduce(0){|sum, x| sum += x[1]}/1000000000000000000.0).to_s]
puts "  Exec Fees : %0.2f Fil" % [(exec_fees.reduce(0){|sum, x| sum += x[1]}/1000000000000000000.0).to_s]
puts "  Payments  : %0.2f Fil" % [(payments.reduce(0){|sum, x| sum += x[1]}/1000000000000000000.0).to_s]
puts "  Rewards   : %0.2f Fil" % [(rewards.reduce(0){|sum, x| sum += x[1]}/1000000000000000000.0).to_s]
p exceptions
p exceptions.map{|from, to, type, value, timestamp| [from, to]}.flatten.sort.uniq.reject{|x| addresses.include? x}
