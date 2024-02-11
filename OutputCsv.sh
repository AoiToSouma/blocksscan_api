#!/bin/bash

source .env

outfile=${csvfile}_$(date +%Y%m%d_%H%M%S).csv

#header
echo "id,wallet_name,wallet_address,symbol,balance,balance(wei),decimals,address_updatedAt,transition,price(usd),price(base),currency,remarks,createdAt" > ${outfile}

#data
sqlite3 data/${dbname} "select * from history;" | sed 's/|/,/g' >> ${outfile}

