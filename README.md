# blocksscan_api
Record changes in the wallet's XRC20 token balance using [Blocksscan Api](https://xdc.blocksscan.io/docs/).<br>
Record to DB using sqlite.<br>

# Install the repo
```
git clone https://github.com/AoiToSouma/blocksscan_api.git
cd blocksscan_api
chmod +x *.sh
```

# Edit configuration
```
nano .env
```
sleeptime : API execution interval(defalut is 300 seconds)<br>
dbname : sqlite DB name for logging records<br>
csvfile :　Prefix of CSV file when outputting records from DB<br>

# Edit address informations
```
nano address.json
```
Register the addresses to monitor.<br>
If you want to monitor only a specific token, also include the token address.<br>
Records in json format.
# Initial setting
```
./initialize.sh
```
Firstly, "sqlite3", "bc", "jq" package is required.<br>
If these packages are not installed, this process will automatically install them.<br>
The DB will be created in the "data" directory.<br>

# Wallet monitoring
```
pm2 BalanceCheck.sh
```
If there is a difference between the XRC20 token in the wallet and the previous value, it will be recorded in the DB.

# Output data to csv file
```
./OutputCsv.sh 
```
It can be loaded into a spreadsheet.
