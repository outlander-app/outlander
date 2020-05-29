#!/bin/sh

xcodebuild -workspace app/src/Outlander.xcworkspace \
       -scheme Outlander \
       clean test \
       CODE_SIGNING_ALLOWED=NO