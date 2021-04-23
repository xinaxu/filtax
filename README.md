# filtax

## Disclaimer
This is a tool used to figure out the earning and loss incurred on Filecoin network for list of wallets or miner addresses. It does not calculate the tax for you. For tax advise, consult with your tax professionals.

## Usage
```
sudo apt install ruby
sudo gem install bundler
sudo bundler install
./filtax.rb -a wallet1,address2,miner3
```

## Notes
* Please provide all your wallet addresses and miner addresses to the tool. All transactions between those addresses will be considered internal transfer and will not be counted.
* The tool relies on official block explorer (filfox.info). The website has a delay generating the transaction pages so by default we only extract data 14 days ago. To change this behavior, add `-d <num>` to the command.
* Since data extraction takes time, the tool will save the downloaded data in local json files and reuse those local cache. If you'd like to update the cache with latest data, add `-u` to the command. You can also delete the local cache files and the tool will start extraction from the oldest date.
* The summary csv file is generated for each month and aggregated for each day. The price for each day is fetched from coingecko.com. You can upload the csv to most of accounting software.
* Any transaction with external wallet will be recorded in exception csv files. You need to manually check and identify each entry.
