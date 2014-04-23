# Intro
I use this script to deploy Mac Apps that I deliver direct to the the customer (not via the Mac App Store). This script is heavily customised but shoud suit as a starting point if you looking to automate your deployments.

The script performs the following operations:  

1. Takes the path of the app from the clipboard (I use a script during the build process to set it).
2. Zips the file.
3. Signs the zip file for Sparkle.
4. Builds the AppCast
5. Creates a deployment script which copies the zip file, AppCast and ReleaseNotes.
 
# Usage
1. Customise the script to you app, local environment and server.
2. Call the script with ./package-update.sh
3. Write the release notes and save them. 
4. Call the generated deployment script to transmit the files with ./deploy-update.sh
5. ???
6. Profit.

# TODO
* Make generic.
* Support beta releases and test environments.
* Generate release notes from git log.
* Automatically tag release with git.
* Switch to arguments rather than grapping file path from the clipboard.

