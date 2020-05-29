#!/bin/sh

xcodebuild -workspace app/src/Outlander.xcworkspace \
       -scheme Outlander \
       clean test