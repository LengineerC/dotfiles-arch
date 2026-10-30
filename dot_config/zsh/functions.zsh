function q(){
	exit
}

function clean-screenshots(){
  find "$HOME/Pictures/Screenshots" -mindepth 1 -exec rm -rf {} \;
}

function proxy() {
  local port="${1:-7890}"
  export http_proxy=http://127.0.0.1:${port};
  export https_proxy=http://127.0.0.1:${port};
  export all_proxy=socks5://127.0.0.1:${port};
  echo "Proxy Enabled on port ${port}"
}

function unproxy(){
  unset http_proxy https_proxy all_proxy
  echo "Proxy Disabled"
}

function cx() {
    local workspace="$HOME/Documents/Codex"

    mkdir -p "$workspace"
    command codex -C "$workspace" "$@" "resume" "--no-daemon"
}

function cxnd() {
    local workspace="$HOME/Documents/Codex"

    if (( $# == 0 )); then
        mkdir -p "$workspace"
        command codex -C "$workspace" resume --no-daemon
    else
        command codex "$@" --no-daemon
    fi
}
