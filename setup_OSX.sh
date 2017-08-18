#!/bin/bash
 
 YELLOW='\033[1;33m'
 RED='\033[1;31m'
 GREEN='\033[1;32m'
 RESET='\033[0m'

# indent text on echo
function indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";;
    *)      sed -u "$c";;
  esac
}

# Grab the current directory
function getCurrent() 
    {
        showStep "getting current directory"
        DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        THIS_SCRIPT=`basename "$0"`
        showStep "Running '${THIS_SCRIPT}'"
    }

# displays where we are, uses the indent function (above) to indent each line
function showStep ()
    {
        echo -e "${YELLOW}=====================================================" | indent
        echo -e "${RESET}-----> $*" | indent
        echo -e "${YELLOW}=====================================================${RESET}" | indent
    }

# check to see if Brew is installed. Install it if it's not already present
# then update and upgrade
function check4Brew ()
    {
        if [[ $BREW_INSTALL == "true" ]]; then
            which brew
            if [ "$?" -ne 0 ]; then
                showStep "${RED}brew not found. installing brew, please accept the installation recommendations"
                /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
            else
                showStep "${GREEN}brew already installed"
            fi
        else   
            showStep "${RED}skipping BREW install"
        fi
        showStep "updating brew to latest version"
        brew update
        showStep "upgrading your installed brew packages"
        brew upgrade
        brew install dos2unix
    }

# check to see if nodev6 is installed. install it if it's not already there. 
function check4node ()
    {
        if [[ $NODE_INSTALL == "true" ]]; then 
            which node
            if [ "$?" -ne 0 ]; then
                showStep "${RED}node not installed. installing Node V6"
                brew install node@6
            else            
                if [[ `brew search /node@6/` != "node@6" ]]; then
                showStep "${RED}found node $? installed, but not V6. installing Node V6"
                brew install node@6
                else
                    showStep "${GREEN}Node V6 already installed"
                fi
            fi
        else   
            showStep "${RED}skipping NODE install"
        fi
    }

# check to see if git is installed. install it if it's not already there. 
function check4git ()
    {
        if [[ $GITHUB_INSTALL == "true" ]]; then
            which git
            if [ "$?" -ne 0 ]; then
                showStep "${RED}git not installed. installing git"
                brew install git
            else
                showStep "${GREEN}git already installed"
            fi
            showStep "downloading GitHub Desktop for OSX"
            curl -O https://mac-installer.github.com/mac/GitHub%20Desktop%20223.zip
            showStep "unzipping GitHub Desktop"
            unzip -o -q 'GitHub%20Desktop%20223.zip'
            showStep "Installing GitHub Desktop"
            yes | cp -rf 'Github Desktop.app' /Applications
            showStep "removing intermediate files"
            rm -r 'Github Desktop.app'
            rm -r 'GitHub%20Desktop%20223.zip'
        else   
            showStep "${RED}skipping git install"
        fi
    }

# Install the node modules required to work with hyperledger composer
function installNodeDev ()
    {
        if [[ $SDK_INSTALL == "true" ]]; then
            showStep "The composer-cli contains all the command line operations for developing business networks."
            npm install -g composer-cli
            showStep "The generator-hyperledger-composer is a Yeoman plugin that creates bespoke applications for your business network."
            npm install -g generator-hyperledger-composer
            showStep "The composer-rest-server uses the Hyperledger Composer LoopBack Connector to connect to a business network, extract the models and then present a page containing the REST APIs that have been generated for the model."
            npm install -g composer-rest-server
            showStep "Yeoman is a tool for generating applications. When combined with the generator-hyperledger-composer component, it can interpret business networks and generate applications based on them."
            npm install -g yo
        else   
            showStep "${RED}skipping NODE SDK for HyperLedger install"
        fi
    }

# create a folder for the hyperledger fabric images and get them from the server
function install_hlf ()
    {
        if [[ $HLF_INSTALL == "true" ]]; then
            if [ ! -d "$HLF_INSTALL_PATH" ]; then
                showStep "creating hlf tools folder $HLF_INSTALL_PATH "
                mkdir -p "$HLF_INSTALL_PATH"
            fi
            cd "$HLF_INSTALL_PATH"
            pwd
            showStep "retrieving image scripts from git"
            curl -O https://raw.githubusercontent.com/hyperledger/composer-tools/master/packages/fabric-dev-servers/fabric-dev-servers.zip
            showStep "unzipping images"
            unzip -o fabric-dev-servers.zip
            showStep "making scripts executable"
            dos2unix `ls *.sh`
            cd fabric-scripts/hlfv1
            dos2unix `ls *.sh`
            showStep "getting docker images for HyperLedger Fabric V1"
            export FABRIC_VERSION=hlfv1
            echo 'export FABRIC_VERSION=hlfv1' >>~/.bash_profile
            cd $HLF_INSTALL_PATH
            ./downloadFabric.sh
            showStep "installing platform specific binaries for OSX"
            curl -sSL https://goo.gl/eYdRbX | bash
            export PATH=$HLF_INSTALL_PATH/bin:$PATH
            export HLF_INSTALL_PATH=$HLF_INSTALL_PATH
            echo "PATH=${HLF_INSTALL_PATH}/bin:"'$PATH' >>~/.bash_profile
            echo "export HLF_INSTALL_PATH=${HLF_INSTALL_PATH}"  >>~/.bash_profile
        else   
            showStep "${RED}skipping HyperLedger Fabric install"
        fi
    }
function printHelp ()
{
    printHeader
    echo ""
    echo -e "${RESET} options for this exec are: "
    echo -e "${GREEN}-h ${RESET}Print this help information" | indent
    echo -e "${GREEN}-g ${RESET}defaults to ${GREEN}true${RESET}. use ${YELLOW}-g false ${RESET}if you do not want to have git installation checked"  | indent
    echo -e "${GREEN}-b ${RESET}defaults to ${GREEN}true${RESET}. use ${YELLOW}-b false ${RESET}if you do not want to have brew installation checked" | indent
    echo -e "${GREEN}-n ${RESET}defaults to ${GREEN}true${RESET}. use ${YELLOW}-n false ${RESET}if you do not want to have node installation checked" | indent
    echo -e "${GREEN}-s ${RESET}defaults to ${GREEN}true${RESET}. use ${YELLOW}-s false ${RESET}if you do not want to have node SDK installation checked" | indent
    echo -e "${GREEN}-d ${RESET}defaults to ${GREEN}true${RESET}. use ${YELLOW}-d false ${RESET}if you do not want to have hypleledger node images verified" | indent
    echo -e "${GREEN}-p ${RESET}defaults to ${GREEN}${HOME}/fabric-tools${RESET}. use ${YELLOW}-p ${HOME}/your/preferred/path/fabric-tools/your/path/here ${RESET}if you want to install hyperledger fabric tools elsewhere." | indent
    echo -e "\t\tonly valid with -d true, ignored otherwise" | indent
    echo ""
    echo ""
}

# print the header information for execution
function printHeader ()
{
    echo ""
    echo -e "${YELLOW}installation script for the Zero To Blockchain Series" | indent
    echo -e "${RED}This is for Mac OSX ONLY" | indent
    echo -e "${YELLOW}This script will check to see if HomeBrew is installed" | indent
    echo -e "${YELLOW}and install it if it's not already present. " | indent
    echo -e "${YELLOW}It will then execute a brew update and brew upgrade to ensure" | indent
    echo -e "${YELLOW}that you are at the latest release of your brew installed packages" | indent
    echo -e "${YELLOW}dos2unix is installed by brew to correct scripts from hyperledger and composer" | indent
    echo -e "${YELLOW}The exec will proceed with checking to ensure you are at Node V6" | indent
    echo -e "${YELLOW}which is required for working with HyperLedger Composer" | indent
    echo -e "${YELLOW}The script will then install the nodejs SDK for hyperledger and composer" | indent
    echo -e "${YELLOW}The script will finish by downloading the docker images for hyperledger${RESET}" | indent
    echo ""
}
# get the command line options

GITHUB_INSTALL="true"
BREW_INSTALL="true"
NODE_INSTALL="true"
SDK_INSTALL="true"
HLF_INSTALL="true"
HLF_INSTALL_PATH="${HOME}/fabric-tools"

 while getopts "h:g:b:n:d:p:s:" opt; 
do
    case "$opt" in
        h|\?)
        printHelp
        exit 0
        ;;
        g)  showStep "option passed for github is: '$OPTARG'" 
            if [[ $OPTARG != "" ]]; then 
                GITHUB_INSTALL=$OPTARG 
            fi
        ;;
        b)  showStep "option passed for brew is: '$OPTARG'" 
            if [[ $OPTARG != "" ]]; then 
                BREW_INSTALL=$OPTARG 
            fi
        ;;
        n)  showStep "option passed for node is: '$OPTARG'" 
            if [[ $OPTARG != "" ]]; then 
                NODE_INSTALL=$OPTARG 
            fi
        ;;
        s)  showStep "option passed for node SDK is: '$OPTARG'" 
            if [[ $OPTARG != "" ]]; then 
                SDK_INSTALL=$OPTARG 
            fi
        ;;
        d)  showStep "option passed for hyperledger docker install is: '$OPTARG'" 
            if [[ $OPTARG != "" ]]; then 
                HLF_INSTALL=$OPTARG 
            fi
        ;;
        p)  showStep "option passed for fabric tools path is: '$OPTARG'" 
            if [[ $OPTARG != "" ]]; then 
                HLF_INSTALL_PATH=$OPTARG 
            fi
        ;;
    esac
 done

    printHeader
    echo  "Parameters:"
    echo -e "Install github? ${GREEN}$GITHUB_INSTALL${RESET}" | indent
    echo -e "Install brew? ${GREEN} $BREW_INSTALL ${RESET}" | indent
    echo -e "Install nodejs? ${GREEN} $NODE_INSTALL ${RESET}" | indent
    echo -e "Install nodejs SDK? ${GREEN} $SDK_INSTALL ${RESET}" | indent
    echo -e "Install HyperLedger Fabric? ${GREEN} $HLF_INSTALL ${RESET}" | indent
    echo -e "Hyperledger fabric tools install path? ${GREEN} $HLF_INSTALL_PATH ${RESET}" | indent


    getCurrent
    showStep "checking Brew"
    check4Brew
    showStep "checking git"
    check4git
    showStep "checking nodejs"
    check4node
    showStep "installing nodejs SDK for hyperledger composer"
    installNodeDev
    showStep "installing hyperledger docker images"
    install_hlf
    showStep "installation complete"