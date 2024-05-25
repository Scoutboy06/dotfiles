#!/usr/bin/env bash

# Update packages and Upgrade system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install packages
packages=(
	git
	curl
	neovim
	python3
	python3-pip
)

for package in "${packages[@]}"; do
	if dpkg -l | grep -q ${package}; then
		echo "${package} is already installed"
	else
		echo "Installing ${package}..."
		sudo apt-get install -y ${package}
	fi
done

# Install NvChad (for neovim)
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1

# Install Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install NVM and Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

# Install eza (ls alternative)
cargo install eza
