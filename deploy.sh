#!/bin/bash

CODE=/home/reednj/code
APP=$CODE/redditcounter.git
CONFIG=$CODE/config_backup/redditcounter/

# just copy everything from the config backup into
# the app folder...
cp $CONFIG/* $APP/
