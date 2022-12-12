#!/bin/bash

# Variables
ipsw=$1

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo."
  exit 1
fi

mkdir -p ipsw

print("Press 1 if the device is iPhone8,1")
print("Press 2 if the device is iPhone9,1 or iPhone9,3")
print("Press 3 if the device is iPhone9,2 or iPhone 9,4")
print("Press 4 if the device is iPhone10,1 or iPhone10,4")
print("Press 5 if the device is iPhone10,2 or iPhone 10,5")

device = input()

if device == "1":
  ipsw = "iPhone8,1"
elif device == "2":
  ipsw = "iPhone9,1 or iPhone9,3"
elif device == "3":
  ipsw = "iPhone9,2 or iPhone 9,4"
elif device == "4":
  ipsw = "iPhone10,1 or iPhone10,4"
elif device == "5":
  ipsw = "iPhone10,2 or iPhone 10,5"
else:
  print("Invalid input")

print("The ipsw variable is set to: " + ipsw)

if [ $ipsw == "iPhone8,1" ]; then
  curl -O http://updates-http.cdn-apple.com/2020WinterFCS/fullrestores/001-87647/45E44665-BF0B-4096-BE86-B6C9DAAD0767/iPhone_4.7_14.3_18C66_Restore.ipsw
elif [ $ipsw == "iPhone9,1" || $ipsw == "iPhone9,3" ]; then
  curl -O http://updates-http.cdn-apple.com/2020WinterFCS/fullrestores/001-87486/23310DA1-A434-4192-87BC-31429FD2D625/iPhone_4.7_P3_14.3_18C66_Restore.ipsw
elif [ $ipsw == "iPhone9,2" || $ipsw == "iPhone9,4" ]; then
  curl -O http://updates-http.cdn-apple.com/2020WinterFCS/fullrestores/001-87451/EE6AEB4B-1BF7-4FBF-9D29-A8C7B970B495/iPhone_5.5_P3_14.3_18C66_Restore.ipsw
elif [ $ipsw == "iPhone10,1" || $ipsw == "iPhone10,4" ]; then
  curl -O http://updates-http.cdn-apple.com/2020WinterFCS/fullrestores/001-87486/23310DA1-A434-4192-87BC-31429FD2D625/iPhone_4.7_P3_14.3_18C66_Restore.ipsw
elif [ $ipsw == "iPhone10,2" || $ipsw == "iPhone10,5" ]; then
  curl -O http://updates-http.cdn-apple.com/2020WinterFCS/fullrestores/001-87451/EE6AEB4B-1BF7-4FBF-9D29-A8C7B970B495/iPhone_5.5_P3_14.3_18C66_Restore.ipsw

for file in *.ipsw; do
  mv "$file" "hereitis"
done

mv hereitis.ipsw ipsw/

fi
