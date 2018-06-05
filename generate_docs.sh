#!/bin/bash

cd HiParsely
doxygen Doxyfile
rsync -Pavz html_docs/* parse.ly:/data/vhosts/parse.ly/sdk/ios
