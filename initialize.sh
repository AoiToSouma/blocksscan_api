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
  balance REAL, \
  wei TEXT, \
  updatedat TEXT, \
  transition REAL, \
  priceusd REAL, \
  pricejpy REAL, \
  remarks TEXT, \
  createdat TEXT);"

#Execution time
exe_time=$(date "+%Y-%m-%dT%H:%M:%S.%3NZ")

#initial value set
xrc20=$(curl -s -X 'GET' \
  "https://xdc.blocksscan.io/api/tokens/holding/XRC20/${wallet_address}" \
  -H 'accept: application/json')

pli=$(echo $xrc20 | jq --arg arg1 "${token_address}" '.items[] | select(.token == $arg1)')
decimals=$(echo $pli | jq '.tokenObj.decimals')

quantity=$(echo $pli | jq '.quantity' | tr -d '"')
updatedAt=$(echo $pli | jq '.updatedAt' | tr -d '"')
priceUSD=$(echo $pli | jq '.tokenObj.priceUSD' | tr -d '"')
hold=$(echo "scale=$decimals; $quantity * 10^-$decimals" | bc)

coingecko=$(curl -s -X 'GET' \
  "https://api.coingecko.com/api/v3/simple/price?ids=plugin&vs_currencies=jpy" \
  -H 'accept: application/json')

priceJPY=$(echo $coingecko | jq '.plugin.jpy')

#insert value
sqlite3 data/${dbname} "INSERT INTO history(balance, wei, updatedat, transition, priceusd, pricejpy, remarks, createdat) \
  VALUES(${hold}, '${quantity}', '${updatedAt}', 0, ${priceUSD}, ${priceJPY}, 'initial', '${exe_time}');" 

echo -e "${GREEN}## Insert history...${NC}"
