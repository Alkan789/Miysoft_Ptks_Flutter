#!/bin/bash

# pubspec.yaml dosyasının yolunu belirtin
pubspec_file="pubspec.yaml"

# Versiyon ve build numarasını okuyun
current_version=$(grep -oP 'version:\s*\K[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+' $pubspec_file)

# Versiyon ve build numarasını parçalara ayırın
IFS='+' read -r version_part build_part <<< "$current_version"

# Build numarasını artırın
new_build=$((build_part + 1))

# Yeni versiyon ve build numarasını birleştirin
new_version="$version_part+$new_build"

# pubspec.yaml dosyasındaki versiyon ve build numarasını güncelleyin
sed -i "s/version: $current_version/version: $new_version/" $pubspec_file

echo "Versiyon güncellendi: $new_version"