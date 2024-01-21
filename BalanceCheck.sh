#!/bin/bash

# Set Colour Vars
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

source .env

while true; do
    # Execution time
    exe_time=$(date "+%Y-%m-%dT%H:%M:%S.%3NZ")

    # Get list token holding of a holder
    xrc20=$(curl -s -X 'GET' \
      "https://xdc.blocksscan.io/api/tokens/holding/XRC20/${wallet_address}" \
      -H 'accept: application/json') > /dev/null 2>&1
    pli=$(echo $xrc20 | jq --arg arg1 "${token_address}" '.items[] | select(.token == $arg1)')
    decimals=$(echo $pli | jq '.tokenObj.decimals')
    quantity=$(echo $pli | jq '.quantity' | tr -d '"')
    updatedAt=$(echo $pli | jq '.updatedAt' | tr -d '"')
    priceUSD=$(echo $pli | jq '.tokenObj.priceUSD' | tr -d '"')
    hold=$(echo "scale=$decimals; $quantity * 10^-$decimals" | bc)

    if [ "${prequantity}" = "" ]; then
        maxid=$(sqlite3 data/${dbname} "SELECT MAX(id) from history;")
        predata=$(sqlite3 data/${dbname} "SELECT balance, wei from history where id = ${maxid};")
        prehold=$(echo $predata | cut -d '|' -f 1)
        prequantity=$(echo $predata | cut -d '|' -f 2)
    fi

    if [ "${quantity}" != "${prequantity}" ]; then
        coingecko=$(curl -s -X 'GET' \
          "https://api.coingecko.com/api/v3/simple/price?ids=plugin&vs_currencies=jpy" \
          -H 'accept: application/json') > /dev/null 2>&1
        priceJPY=$(echo $coingecko | jq '.plugin.jpy')
        transition=$(echo "scale=$decimals; ($prequantity - $quantity) * 10^-$decimals" | bc)

        # Insert history
        sqlite3 data/${dbname} "INSERT INTO history(balance, wei, updatedat, transition, priceusd, pricejpy, remarks, createdat) \
          VALUES(${hold}, '${quantity}', '${updatedAt}', ${transition}, ${priceUSD}, ${priceJPY}, 'initial', '${exe_time}');"

        echo "処理日時 : ${exe_time}==========================="
        echo "  walletの更新日時 : ${updatedAt}"
        echo "  pli残高          : ${hold} pli"
        echo "  USD              : ${priceUSD} usd"
        echo "  日本円           : ${priceJPY} 円"
        echo ""

    fi
    prequantity=${quantity}
    prehold=${hold}
    sleep ${sleeptime}
done
