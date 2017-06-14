#!/bin/bash
source /etc/dohko
source /etc/h2

eval "(nohup /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf) &"