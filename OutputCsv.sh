#!/bin/bash

source .env

outfile=${csvfile}_$(date +%Y%m%d_%H%M%S).csv

#header
echo "id,残高,残高(wei),address更新日時,増減,価格(usd),価格(jpy),補足,データ作成日時" > ${outfile}

#data
sqlite3 data/${dbname} "select * from history;" | sed 's/|/,/g' >> ${outfile}

