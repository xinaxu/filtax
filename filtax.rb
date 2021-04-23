#!/usr/bin/ruby
require 'date'
require 'slop'
require 'rest-client'
require 'json'
require 'set'
require 'open-uri'
require 'csv'

opts = Slop::Options.new
opts.banner = "Usage: ./filtax.rb [options]"
opts.array '-a', '--address', 'Wallet or miner address'
opts.integer '-d', '--day', 'Number of recent days to skip due to slow processing of Filfox', default: 14
opts.boolean '-u', '--update', 'Update cache', default: false
opts.on '-h', '--help', 'print help' do
  puts opts
  exit
end
parser = Slop::Parser.new(opts)
begin
  @options = parser.parse(ARGV)
rescue
  puts opts
  exit
end
@day = @options[:day]
@update_cache = @options[:update]

def get_price
  URI.open('https://www.coingecko.com/price_charts/export/12817/usd.csv', 'rb') do |url|
    url.read
  end
end

def get_transactions(address)
  if File.exists?("#{address}.json")
    result = JSON.parse(File.read("#{address}.json"))
    return result unless @update_cache
  else 
    result = {}
  end

  puts "Retrieving address #{address}"
  page = 0
  loop do
    added = 0
    break_outer = false
    puts "  Page #{page}"
    response = JSON.parse(RestClient.get("https://filfox.info/api/v1/address/#{address}/transfers?pageSize=100&page=#{page}").body)
    # Stop if its beyond the last page
    break if response['transfers'].nil? || response['transfers'].length == 0
    response['transfers'].each do |transfer|
      timestamp = transfer['timestamp']
      from = transfer['from']
      to = transfer['to']
      value = transfer['value']
      message = transfer['message']
      type = transfer['type']
      # Skip recent dates because it takes time for Filfox to generate accurate transaction list
      next if Date.today - Time.at(timestamp).to_date < @day
      result[timestamp.to_s] = [] unless result.has_key? timestamp.to_s
      if result[timestamp.to_s].any? {|entry| entry['from'] == from && entry['to'] == to && entry['value'] == value && entry['message'] == message && entry['type'] == type }
        # If there is duplicate
        if added == 0
          break_outer = true
          break
        else
          next
        end
      end
      result[timestamp.to_s] << {'from' => from, 'to' => to, 'value' => value, 'message' => message, 'type' => type}
      added += 1
    end
    break if break_outer
    page += 1
  end

  File.write("#{address}.json", JSON.generate(result))
  result
end

summary = {}
exception = {}

prices = CSV.new(get_price, headers: true).map{|row| [Date.parse(row['snapped_at']).to_s, row['price'].to_f * 1e-18]}.to_h
addresses = Set.new(@options[:address])
addresses.each do |address|
  get_transactions(address).each do |timestamp, entries|
    entries.each do |entry|
      time = Time.at(timestamp.to_i).to_datetime
      key = "#{time.year}-#{time.month}"
      next if addresses.include?(entry['from']) && addresses.include?(entry['to'])
      summary[key] = [] unless summary.has_key? key
      other = addresses.include?(entry['from']) ? entry['to'] : entry['from']
      date_str = time.to_date.to_s < '2020-10-15' ? '2020-10-15' : time.to_date.to_s
      case other
      when 'f099'
        summary[key].push([time.to_date.to_s, "Penalty or gas fee", entry['value'].to_i * prices[date_str]])
      when 'f05'
        summary[key].push([time.to_date.to_s, "Deal making and publishing", entry['value'].to_i * prices[date_str]])
      when 'f01'
        summary[key].push([time.to_date.to_s, "Deal execution", entry['value'].to_i * prices[date_str]])
      when 'f02'
        summary[key].push([time.to_date.to_s, "Block reward", entry['value'].to_i * prices[date_str]])
      else
        if entry['type'] == 'miner-fee'
          summary[key].push([time.to_date.to_s, "Miner fee", entry['value'].to_i * prices[date_str]])
        elsif other == entry['to'] && other.length < 10
          summary[key].push([time.to_date.to_s, "Deal payment", entry['value'].to_i * prices[date_str]])
        else
          exception[key] = [] unless exception.has_key? key
          exception[key].push([time.to_date.to_s, "#{entry['type']} with #{other} - #{entry['message']}", entry['value'].to_i * prices[date_str]])
        end
      end
    end
  end
end
summary.each do |key, transactions|
  CSV.open("#{key}.csv", "wb") do |csv|
    csv << ['Date', 'Description', 'Amount']
    transactions.group_by { |t| t[0..1].join('#') }.map{|dd, ts| [dd.split('#')[0], dd.split('#')[1], "%.2f" % [ts.reduce(0.0){|s, t| s += t[2]}]]}.each do |t|
      csv << t if t[2] != '0.00' && t[2] != '-0.00'
    end
  end
end
exception.each do |key, transactions|
  CSV.open("#{key}.exception.csv", "wb") do |csv|
    csv << ['Date', 'Description', 'Amount']
    transactions.each do |t|
      csv << [t[0], t[1], "%.2f" % [t[2]]]
    end
  end
end
