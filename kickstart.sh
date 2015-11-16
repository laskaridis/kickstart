#! /bin/bash

kickstart_puts() {
  local fmt="$1"; shift

  printf "\n$fmt\n" "$@"
}

kickstart_package_is_installed() {
  dpkg -s "$1" 2>/dev/null | grep -c "ok installed" >/dev/null
}

kickstart_package_install() {
  if kickstart_package_is_installed "$1"; then
    kickstart_puts "Package %s is already installed ..." "$1"
  else
    kickstart_puts "Installing %s ..." "$1"
  fi
}

kickstart_install_rvm() {
  if kickstart_rvm_is_installed ; then
    kickstart_puts "RVM is already installed ..."
    if (( $noupdate = 0 )) 2>/dev/null ; then
      kickstart_puts "Upgrading RVM ..."

      kickstart_upgrade_rvm
    fi
  else
    kickstart_puts "Installing RVM ..."
  fi

}

kickstart_rvm_is_installed() {
  rvm --version 2>/dev/null | grep -c "rvm" >/dev/null
}

kickstart_upgrade_rvm() {
  rvm get stable 1>/dev/null
}

kickstart_install_ruby() {
  local version="2.2.3"

  if kickstart_ruby_is_installed ; then
    kickstart_puts "Ruby %s is already installed ..." $version
  else
    kickstart_puts "Installing ruby %s ..." $version
  fi
}

kickstart_ruby_is_installed() {
  rvm list 2>/dev/null | grep -c "ruby-2.2.3" >/dev/null
}

kickstart_gem_install_or_update() {
  if gem list "$1" --installed > /dev/null; then
    kickstart_puts "Gem %s is already installed ..." "$1"
    if (( $noupdate = 0)) 2>/dev/null ; then
      kickstart_puts "Updating %s ..." "$1"
      gem update "$@"
    fi
  else
    kickstart_puts "Installing %s ..." "$1"
    gem install "$@"
  fi
}


kickstart_usage() {
  printf "%b" "
Usage

  kickstart [options]

Options

  [[--]ruby-version] <version>

  The ruby version to install. Valid values are:

    <x>.<y>.<z> - Major version x, minor version y and patch z.

  [[--]help]

  Display this output
"
}

p() {
  kickstart_puts "$1"
}

kickstart_parse_params() {
  while (( $# > 0 )); do
    token="$1"
    shift
    case "$token" in
      (--ruby-version)
        if [[ -n "${1:-}" ]]; then
          ruby_version="$1"
          shift
        fi
        ;;

      (--no-update)
        noupdate=1
        ;;

      (--help)
        kickstart_usage
        exit 0
        ;;

      (*)
        kickstart_usage
        exit 1
        ;;
    esac
  done
}

kickstart_install_packages() {
  kickstart_package_install 'curl'
  kickstart_package_install 'git'
  kickstart_package_install 'vim'
  kickstart_package_install 'exuberant-ctags'
  kickstart_package_install 'silversearcher-ag'
  kickstart_package_install 'qt'
  kickstart_package_install 'openssl'
}

kickstart_install_gems() {
  kickstart_gem_install_or_update 'bundler'
}

kickstart_install_extensions() {
  if [[ -f "$HOME/.kickstart.local" ]]; then
    kickstart_puts "Installing extensions ..."
    . "$HOME/.kickstart.local"
  else
    kickstart_puts "No extensions found ..."
  fi
}

kickstart() {
  kickstart_init_defaults
  kickstart_parse_params "$@"
  kickstart_install_packages
  kickstart_install_rvm
  kickstart_install_ruby
  kickstart_install_gems
  kickstart_install_extensions

  kickstart_puts "Installation completed!"
  exit 0
}

kickstart "$@"
