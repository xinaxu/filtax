#!/usr/bin/ruby
wallets = `lotus wallet list | tail -n +2 | cut -d' ' -f1`.lines.map{|x|x.strip}
wallets += ['f064218','f0455466','f0440182','f0440208','f0440040','f1s2sduqpiucfqo3my743dgwuiazor6tovq4xsiyy', 'f0838852', 'f0838873', 'f0838893', 'f0838923']
puts "./filtax.rb -a #{wallets.join(',')} -u"
