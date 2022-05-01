#!/bin/sh
# Oh My ZSH plugins. Visit https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
OMZPLUGINS="aws catimg chucknorris docker git gcloud kubectl tmux ubuntu"

PACKAGES="curl fortune git tmux zsh"

USERDIR="/mnt/c/Users/$(powershell.exe '$env:UserName' | tr -d '\n\r' )"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' 

prereq() {
	if [ "$(powershell.exe 'Get-ExecutionPolicy' | tr -d '\n\r' )" != "Unrestricted" ]; then
		echo ""
		echo "${RED}[ERROR]${NC} Halting execution of script as Powershell execution policy is not Unrestricted"
		echo "${RED}[ERROR]${NC} Please open an Admin powershell terminal as administrator and run ${RED}Set-ExecutionPolicy Unrestricted${NC}"
		echo ""
		exit 125
	else
		echo ""
		echo "${GREEN}[INFO]${NC} Powershell execution policy checked. Good to proceed"
		echo ""
	fi
}

install () {
    sudo apt-get update

    sudo apt-get install curl git zsh

    chsh -s $(which zsh)

    [ -d ${USERDIR}/code ] || mkdir ${USERDIR}/code
}

fonts () {
    cd ${USERDIR}/code
    if [ -d nerd-fonts ]; then
		cd nerd-fonts
		git pull
    else
    	git clone https://github.com/ryanoasis/nerd-fonts.git
    	cd nerd-fonts
	fi
    powershell.exe -File ./install.ps1
}


ohMyZsh () {
	rm -rf /home/paolo/.oh-my-zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
}

configure () {
	if [ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]; then
		cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
		git pull
		cd -
	else
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	fi
	if grep "^ZSH_THEME" ~/.zshrc > /dev/null; then
        sed -Ei 's#^ZSH_THEME=.+$#ZSH_THEME="powerlevel10k/powerlevel10k"#' ~/.zshrc
    else
    	echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> ~/.zshrc
    fi
    sed -i "s#^plugins=.*#plugins=(${OMZPLUGINS})#" ~/.zshrc
	if ! $(grep "hash -d h=${USERDIR}" ~/.zshrc > /dev/null); then 
		echo "hash -d h=${USERDIR}" >> ~/.zshrc
	fi
    echo ""
    echo "${GREEN}[INFO]${NC} Bootstrap completed. Please terminate WSL, select font (suggested MesloLGS NF), then start and run p10k configure if autoconfiguration doesn't start"
	echo "${YELLOW}[WARN]${NC} Please remember to reset as Restricted the Execution policy. To do it open an Admin powershell terminal as administrator and run ${RED}Set-ExecutionPolicy Restricted${NC}"
	echo ""
}

main () {
    prereq
	install
	fonts
	ohMyZsh
	configure
}

main "$@"
