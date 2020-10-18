#!/bin/sh 
cd ../
ssg5 src ../blog-dst "Alan's Blog" "https://alnn.tech" 
cd ../blog-dst 
git pull
git add . 
git commit -m "Building"
git push
