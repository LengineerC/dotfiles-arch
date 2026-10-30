# KVM显卡直通和内存大页切换
alias vfio-start="sudo $HOME/.local/bin/kvm-passthrough start"
alias vfio-stop="sudo $HOME/.local/bin/kvm-passthrough stop"

# 开启热点
alias hotspot-on="sudo nmcli device wifi hotspot ifname wlan0 ssid Lens password 12345678 band a"
alias hotspot-off="sudo nmcli connection down Hotspot"

# neovim
alias nvd="neovide"
alias nv="nvim"

# system cmd alias
alias grep="grep --color=auto"
alias ...="cd ../../"

# kitty
alias icat="kitten icat"
alias kclip="kitten clipboard"
alias kdiff="kitten diff"
alias kssh="kitten ssh"
alias kuni="kitten unicode_input"
alias ktrans="kitten transfer"
