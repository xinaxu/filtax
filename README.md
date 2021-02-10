# filtax

## Disclaimer
This is a tool used to figure out the earning and loss incurred on Filecoin network for list of wallets or miner addresses. It does not calculate the tax for you.
If you agree with below assumptions, you should not use this tool because the assumptions are highly likely incorrect. Instead, you should consult your own tax experts for your tax calculation.
If you disagree with below assumptions, then use it at your own risk.

## Assumptions
1. Receiving fund from crypto exchange address are considered buying the Filecoin and owning the Filecoin assets
2. All rewards, receiving fund from unrecognized addresses or faucet are considered business gain and owning the Filecoin assets
3. For above 1 and 2 cases, we track dates to figure out the cost basis later
4. Send fund to crypto exchange address are considered selling the Filecoin and making capital gain/loss, we use FIFO to figure out the cost basis. This is to maximize the possibility of utilizing long-term capital gain tax benefit.
5. All burn fee, miner fee, deal making, payments, send fund to unrecognized addresses are considered business loss and making capital gain/loss. we use LIFO to figure out the cost basis. This is to minimize short-term capital gain/loss.

## Usage
```
sudo apt install ruby
sudo gem install bundler
sudo bundler install
./filtax.rb -a wallet1,address2,miner3 -y 2020
```
