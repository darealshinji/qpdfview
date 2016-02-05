#!/usr/bin/env bash

if [ "$(uname -o)" = "GNU/Linux" ]; then
	depends_dir="$HOME/.local/share/depends_exe"
	depends_exe="wine $depends_dir/depends.exe"
else
	depends_dir="/usr/local/bin"
	depends_exe="depends"
fi

function errorExit() {
	echo ""
	echo "error: $1"
	exit 1
}

function copy_dlls() {
	file="${1}"
	outdir="${2}"
	txt="deps-$(basename ${file}).txt"

	if [ "$(uname -o)" = "GNU/Linux" ]; then
		wine "$depends_dir/depends.exe" -c -oc:"$txt" "$file" 2>/dev/null
		echo "warning: automatic copying of dependencies not (yet) possible on GNU/Linux"
		echo ""
		grep '^,.*\.DLL' "$txt" | cut -d '"' -f2 | tr [A-Z] [a-z]
	else
		printf "analyzing \`$file'... "
		depends -c -oc:"$txt" "$file"
		cygpath="$(cygpath -d / | sed -r 's|.|\L&|; s|\\|\\\\|g')"
		file_lower="$(basename ${file} | tr [A-Z] [a-z])"
		dlls="$(grep "$cygpath" "$txt" | cut -d, -f2 | tr [A-Z] [a-z] | \
			sed -e 's|\\|/|g; s|"||g' | grep -v "${file_lower}$")"
		echo "done"

		mkdir -p "$outdir"
		echo "copy dependencies:"
		for f in $dlls; do
			cp -vf "$f" "$outdir"
		done
	fi
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

if [ ! -e "$input" ]; then
	errorExit "cannot open \`$input' (No such file or directory)"
fi

if [ "$(uname -o)" = "GNU/Linux" ]; then
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

