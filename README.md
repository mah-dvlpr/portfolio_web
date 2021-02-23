# Flutter Based Web Page Presenting My Software Portfolio
This repo is meant to present, and be part of, my software portfolio.

# How to build and use with any server
run:
```
cd 'path/to/this/project'  
flutter build web
```

Then set the servers root directory to the absolute path of 'path/to/this/project/build/web/'.

With Flutter, you can run:
```
flutter pub global activate dhttpd
flutter pub global run dhttpd --path 'path/to/this/project/build/web/'
```