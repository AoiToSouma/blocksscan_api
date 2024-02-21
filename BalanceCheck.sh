#!/bin/bash

# Set Colour Vars
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

source .env

FUNC_GET_VALUE() {
    symbol=$(echo $1 | jq -r '.tokenObj.symbol')
    decimals=$(echo $1 | jq '.tokenObj.decimals')
    quantity=$(echo $1 | jq -r '.quantity')
    updatedAt=$(echo $1 | jq -r '.updatedAt')
    priceUSD=$(echo $1 | jq -r '.tokenObj.priceUSD')
    coingeckoID=$(echo $1 |jq -r '.tokenObj.coingeckoID')
    hold=$(echo "scale=$decimals; $quantity * 10^-$decimals" | bc)
    format=$(echo ${hold} | xargs printf %.10f)
}

FUNC_INSERT_HISTORY() {
# $1  : wallet_name
# $2  : wallet_address
# $3  : symbol
# $4  : formatted price
# $5  : quantity
# $6  : decimals
# $7  : updatedAt
# $8  : transition
# $9  : priceUSD
# $10 : priceCurrency
# $11 : baseCurrency
# $12 : remarks
# $13 : created time
    sqlite3 data/${dbname} \
    "INSERT INTO history(walletname, walletaddress, symbol, balance, wei, decimals, updatedat, transition, \
                         priceusd, price, currency, remarks, createdat) \
     VALUES('${1}', '${2}', '${3}', ${4}, '${5}', ${6}, '${7}', ${8}, ${9}, ${10}, '${11}', '${12}', '${13}');"
}

FUNC_GET_COINGECKO() {
# $1 : token
    coingecko=$(curl -s -X 'GET' \
      "https://api.coingecko.com/api/v3/simple/price?ids=${1}&vs_currencies=${baseCurrency}" \
      -H 'accept: application/json')
#coingecko="{\"${coingeckoID}\":{\"jpy\":8.04e-06}}"
}

while true; do
    # Execution time
    exe_time=$(date "+%Y-%m-%dT%H:%M:%S.%3NZ")
    # Source information
    cat address.json | jq -c '.data[]' |
    while read -r data; do
        wallet_name=$(echo "${data}" | jq -r '.wallet_name')
        wallet_address=$(echo "${data}" | jq -r '.wallet_address')
        token_address=$(echo "${data}" | jq -r '.token_address // "NA"')
        interval_timer=$(echo "${data}" | jq -r '.interval_timer // "NA"')

        if [ "${interval_timer}" != "NA" ]; then
            if [ "${pre_time}" != "" ]; then
                elapsed_time=$(echo $(expr `date -d"${exe_time}" +%s` - `date -d"${pre_time}" +%s`))
                if [ $(( elapsed_time )) -lt $(( interval_timer )) ]; then
                    # Skip
                    continue
                fi
            fi
        fi

        echo "[${wallet_name}] ${exe_time} ========================================"
        # Get list token holding of a holder
        xrc20=$(curl -s -X 'GET' \
          "https://xdc.blocksscan.io/api/tokens/holding/XRC20/${wallet_address}" \
          -H 'accept: application/json')
        if [ ${token_address} == "NA" ]; then
            echo "${xrc20}" | jq -c '.items[]' |
            while read -r items; do
                token=$(echo "${items}" | jq -r '.token')
                FUNC_GET_VALUE "${items}"

                # Get previous value
                maxid=$(sqlite3 data/${dbname} "SELECT MAX(id) from history where walletaddress = '${wallet_address}' and symbol = '${symbol}';")

                # Initial status check
                if [ "${maxid}" == "" ]; then
                    echo "[Initialization] ${symbol} : ${quantity}"
                    # get value from coingecko
                    FUNC_GET_COINGECKO ${coingeckoID}
                    priceCurrency=$(echo $coingecko | jq '."'${coingeckoID}'".'${baseCurrency})
                    # Insert table
                    FUNC_INSERT_HISTORY ${wallet_name} ${wallet_address} ${symbol} ${format} ${quantity} ${decimals} \
                            ${updatedAt} 0 ${priceUSD} ${priceCurrency} ${baseCurrency} 'initial' ${exe_time}
                else
                    predata=$(sqlite3 data/${dbname} "SELECT balance, wei from history where id = ${maxid};")
                    prehold=$(echo $predata | cut -d '|' -f 1)
                    prequantity=$(echo $predata | cut -d '|' -f 2)
                    if [ "${quantity}" != "${prequantity}" ]; then
                        echo "[There are differences.] ${symbol} : ${prequantity} -> ${quantity}"
                        # get value from coingecko
                        FUNC_GET_COINGECKO ${coingeckoID}
                        priceCurrency=$(echo $coingecko | jq '."'${coingeckoID}'".'${baseCurrency})
                        # calculate the difference
                        transition=$(echo "${quantity} - ${prequantity}" | bc)
                        # Insert table
                        FUNC_INSERT_HISTORY ${wallet_name} ${wallet_address} ${symbol} ${format} ${quantity} ${decimals} \
                                ${updatedAt} ${transition} ${priceUSD} ${priceCurrency} ${baseCurrency} '' ${exe_time}
                    fi
                fi
            done
        else
            # Replace 0x with xdc, replace uppercase letters with lowercase letters
            token_address="$(echo ${token_address} | sed '/^$/d;/^\\s*$/d;s/^0x/xdc/g' | tr '[:upper:]' '[:lower:]')"

            # Get information on specified token
            token=$(echo ${xrc20} | jq --arg arg1 "${token_address}" '.items[] | select(.token == $arg1)')
            FUNC_GET_VALUE "${token}"
            # Get previous value
            maxid=$(sqlite3 data/${dbname} "SELECT MAX(id) from history where walletaddress = '${wallet_address}' and symbol = '${symbol}';")

            # Initial status check
            if [ "${maxid}" == "" ]; then
                echo "[Initialization] ${symbol} : ${quantity}"
                # get value from coingecko
                FUNC_GET_COINGECKO ${coingeckoID}
                priceCurrency=$(echo $coingecko | jq '."'${coingeckoID}'".'${baseCurrency})
                # Insert table
                FUNC_INSERT_HISTORY ${wallet_name} ${wallet_address} ${symbol} ${format} ${quantity} ${decimals} \
                        ${updatedAt} 0 ${priceUSD} ${priceCurrency} ${baseCurrency} 'initial' ${exe_time}
            else
                predata=$(sqlite3 data/${dbname} "SELECT balance, wei from history where id = ${maxid};")
                prehold=$(echo $predata | cut -d '|' -f 1)
                prequantity=$(echo $predata | cut -d '|' -f 2)
                if [ "${quantity}" != "${prequantity}" ]; then
                    echo "[There are differences.] ${symbol} : ${prequantity} -> ${quantity}"
                    # get value from coingecko
                    FUNC_GET_COINGECKO ${coingeckoID}
                    priceCurrency=$(echo $coingecko | jq '."'${coingeckoID}'".'${baseCurrency})
                    # calculate the difference
                    transition=$(echo "${quantity} - ${prequantity}" | bc)
                    # Insert table
                    FUNC_INSERT_HISTORY ${wallet_name} ${wallet_address} ${symbol} ${format} ${quantity} ${decimals} \
                            ${updatedAt} ${transition} ${priceUSD} ${priceCurrency} ${baseCurrency} '' ${exe_time}
                fi
            fi
        fi
    done
    pre_time=${exe_time}
    sleep ${sleeptime}
done
