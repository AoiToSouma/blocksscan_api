#!/bin/bash

# Set Colour Vars
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

pkgexist=$(which sqlite3)
if [ "${pkgexist}" = "" ]; then
    echo -e "${GREEN}## Install: sqlite3 ...${NC}"
    sudo apt install sqlite3
fi
pkgexist=$(which bc)
if [ "${pkgexist}" = "" ]; then
    echo -e "${GREEN}## Install: bc ...${NC}"
    sudo apt install bc
fi
pkgexist=$(which jq)
if [ "${pkgexist}" = "" ]; then
    echo -e "${GREEN}## Install: jq ...${NC}"
    sudo apt install jq
fi

curdir=$(echo `pwd`)
workdir=$(cd $(dirname $0); pwd)
if [ "${curdir}" != "${workdir}" ]; then
    cd ${workdir}
fi

source .env

if [ ! -d "data" ]; then
    echo -e "${GREEN}## Make directory: data ...${NC}"
    mkdir data
fi

if [ -f data/${dbname} ]; then
    echo -e "${RED}data/${dbname} is exist."
    while true; do
        read -p "Do you want to initialize?(Y/n) " _input
        case $_input in
            [Yy][Ee][Ss]|[Yy]* )
                rm -f data/${dbname}
                echo -e "data/${dbname} is deleted."
                break
                ;;
            [Nn][Oo]|[Nn]* ) 
                echo -e "${GREEN}Initialization canceled.${NC}"
                exit 0
                ;;
            * ) echo "Please answer (y)es or (n)o.";;
        esac
    done
    echo -e "${NC}"
fi

#create DB
echo -e "${GREEN}## Create DB: data/${dbname} ...${NC}"
echo ".open data/${dbname}" | sqlite3

#create table history
echo -e "${GREEN}## Create TABLE history...${NC}"
sqlite3 data/${dbname} "CREATE TABLE history( \
  id INTEGER PRIMARY KEY AUTOINCREMENT, \
  walletname TEXT, \
  walletaddress TEXT, \
  symbol TEXT, \
  balance REAL, \
  wei TEXT, \
  decimals INTEGER, \
  updatedat TEXT, \
  transition TEXT, \
  priceusd REAL, \
  price REAL, \
  currency TEXT, \
  remarks TEXT, \
  createdat TEXT);"
