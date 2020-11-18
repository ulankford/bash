#!/bin/bash
ssh -L 1080:localhost:1080 nagios.smarts-systems.com -t ssh root@tlx -D1080
