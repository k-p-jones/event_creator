### SETUP
# This needs to be scripted

First you will need to go to google and register your app and get the client secret json file and dump it in the top level directory of the app.

bundle install

Then you will need to create a log dir and file `mkdir -p logs/nelly.log`

Then we need to set the ENV variables with a gmail username and password and credentials path

We also will need a calendar_id.

Then we will have to run the calendar authorization on its own in order to generate the tokens etc 

Then run a scan of the last 12 months

Then edit the cron tab.

Then reboot.