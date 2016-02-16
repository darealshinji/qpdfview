#!/usr/bin/env bash

# Copyright (C) 2016  djcj <djcj@gmx.de>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# TODO:
#  - add search paths via CLI option
#  - avoid redundant dll copying
#  - don't copy input dlls


case "$(uname -o)" in
	"Msys"|"Cygwin")
		depends_dir="/usr/local/bin"
		unix="no"
		;;
	*)
		depends_dir="$HOME/.local/share/depends_exe"
		unix="yes"
		;;
esac

function errorExit() {
	echo ""
	echo "error: $1"
	exit 1
}

function copy_dlls() {
	file="${1}"
	outdir="${2}"
	dir="$(dirname "$file")"
	txt="deps-$(basename ${file}).txt"

	if [ "$unix" = "yes" ]; then
		wine "$depends_dir/depends.exe" -c -oc:"$txt" "$file" 2>/dev/null
	else
		export PATH="$dir:$PATH"
		printf "analyzing \`$file'... "
		depends -c -oc:"$txt" "$file"
		echo "done"
	fi

	dlls="$(grep '^,.*\.DLL' "$txt" | cut -d '"' -f2 | tr [A-Z] [a-z])"
	mkdir -p "$outdir"
	echo "copy dependencies:"
	for f in $dlls; do
		# don't rely on depends.exe to print full paths
		f="$(basename "$f")"
		if [ "$unix" = "yes" ]; then
			dll="$(find "$dir" -iname "$f" | head -n1)"
			cp -vf "$dll" "$outdir"
		else
			dll="$(which $f)"
			if ! $(echo "$dll" | grep -q '/c/Windows/'); then 
				cp -vf "$dll" "$outdir"
			fi
		fi
	done
	rm -f "$txt"
}

function get_depends_exe() {
	printf "download and install Dependency Walker... "

	zip=/tmp/depends.zip
	url=http://www.dependencywalker.com/depends22_x86.zip

	rm -f $zip
	if which wget 2>/dev/null 1>/dev/null ; then
		wget -qq -O $zip $url
	elif which curl 2>/dev/null 1>/dev/null ; then
		curl -s $url > $zip
	else
		errorExit "\`wget' or \`curl' not in PATH"
	fi

	(echo "675ca981ddf557eb7d4550624157dbe5 *$zip" | \
	 md5sum -c - 2>/dev/null 1>/dev/null) || \
		errorExit "incorrect checksum"

	if which unzip 2>/dev/null 1>/dev/null ; then
		mkdir -p "$depends_dir"
		pushd "$depends_dir" >/dev/null
		unzip -o -qq $zip
		popd >/dev/null
	else
		errorExit "\`unzip' not in PATH"
	fi

	echo "done"
	echo ""
}

input="$1"
outdir="$2"

if [ -z "$input" ]; then
	echo "usage: $0 <EXE|DLL|DIR> [<OUTDIR>]"
	exit 1
fi

if [ ! -e "$input" ]; then
	errorExit "cannot open \`$input' (No such file or directory)"
fi

if [ "$unix" = "yes" ]; then
	if ! which wine 2>/dev/null 1>/dev/null ; then
		errorExit "\`wine' not in PATH"
	fi
	if [ ! -f "$depends_dir/depends.exe" ]; then
		get_depends_exe
	fi
else
	if ! which depends 2>/dev/null 1>/dev/null ; then
		get_depends_exe
	fi
fi

if [ -d "$1" ]; then
	if [ "x$outdir" = "x" ]; then
		outdir="$(basename $(cd "$input" && pwd))-deps"
	fi
	for f in "$1"/*.exe "$1"/*.dll ; do
		copy_dlls "$f" "$outdir"
		echo ""
	done
elif [ -f "$1" ]; then
	if [ "x$outdir" = "x" ]; then
		outdir="$(basename "$input")-deps"
	fi
	if [ "$(file -b "${1}" | head -c4)" != "PE32" ]; then
		errorExit "\`$input' is not a PE32 binary file"
	fi
	copy_dlls "$1" "$outdir"
fi

