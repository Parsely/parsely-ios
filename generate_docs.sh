#!/bin/bash

doxygen HiParsely/Doxyfile
rsync -Pavz html_docs/* parsely.com:/data/vhosts/www.parsely.com/sdk/ios
