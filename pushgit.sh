#!/bin/bash

git add .

echo Insert Your Commit Desc : 
read commides

git commit -m "$commides"
git push

echo "push done!"

