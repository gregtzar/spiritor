#!/usr/bin/env bash

# Source: https://www.digitalocean.com/community/tutorials/how-to-build-go-executables-for-multiple-platforms-on-ubuntu-16-04

# Usage: build_go.sh [output directory]
# Writes one binary per platform into the output directory, by default the current one.
output_dir=${1:-.}

package=github.com/gregtzar/spiritor

package_split=(${package//\// })
package_name=${package_split[-1]}
	
platforms=("windows/amd64" "windows/386" "darwin/amd64" "darwin/arm64" "linux/amd64" "linux/386")

for platform in "${platforms[@]}"
do
	platform_split=(${platform//\// })
	GOOS=${platform_split[0]}
	GOARCH=${platform_split[1]}
	output_name=$package_name'-'$GOOS'-'$GOARCH
	if [ $GOOS = "windows" ]; then
		output_name+='.exe'
	fi	

	# -trimpath keeps the build machine's file paths out of the published binaries.
	env GOOS=$GOOS GOARCH=$GOARCH go build -trimpath -o "$output_dir/$output_name" $package
	if [ $? -ne 0 ]; then
   		echo 'An error has occurred! Aborting the script execution...'
		exit 1
	fi
done
