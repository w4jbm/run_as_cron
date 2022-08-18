#!/bin/bash
#
# Simple install script for run-as-cron
#
sudo rm -rf /usr/local/bin/run-as-cron || true
sudo ln -s $HOME/Software/run_as_cron/run-as-cron /usr/local/bin/run-as-cron
chmod +x run-as-cron
