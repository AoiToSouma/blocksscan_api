# blocksscan_api
Record changes in the wallet's XRC20 token balance using [Blocksscan Api](https://xdc.blocksscan.io/docs/).<br>
By default, Plugin token is set.<br>
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
token_address : XRC20 token(default is Plugin token)<br>
wallet_address : edit it to your wallet<br>
sleeptime : API execution interval(defalut is 300 seconds)<br>
dbname : sqlite DB name for logging records<br>
csvfile :　Prefix of CSV file when outputting records from DB<br>

# Initial setting
```
./initialize.sh
```
Firstly, "sqlite3", "bc" package is required.<br>
If these packages are not installed, this process will automatically install them.<br>
Secondly, check the current balance of wallet address and create the first record.<br>
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
