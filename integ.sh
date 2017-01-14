#!/bin/bash

# Default action
# 1 = Check if checksum stored and correct, report
# 2 = Add new checksum

digest='sha1'
quiet=0 # 1 = only show mismatched files
verbose=0
debug=1

function show_help {
 cat << EOF
Usage: ${0##*/} [-w] FILE
Check the integ checksum file attribute and optionally add the checksum
  -w     Write a new checksum to FILE
  -v     Verbose messages
  -d     Remove the checksum from FILE
  -f     Set the digest function to write, default 'sha1'

Examples:
   Check a files integrity checksum
     ${0##*/} myfile.jpg

   Write a new checksum to a file
     ${0##*/} -w myfile.jpg

Info:
  When copying files, extended attributes should be preserved to ensure
  integrity data is copied.
  e.g. rsync -X source destination
       osx : cp -p source destination
EOF
  exit 1
}

function generate_checksum {
  digest="$1"
  input_file="$2"
  calc_cs=$(openssl dgst -${digest} "${input_file}" | awk '{print $2}')
  echo "${calc_cs}"
}

function read_checksum {
  input_file="$1"
  if [[ "${OSTYPE}" == 'linux-gnu' ]]; then
    stored_cs=$(getfattr -n "${attrib_key}" "${input_file}" 2>/dev/null  | grep "${attrib_key}" | awk -F'=' '{print $2}' | sed -e 's/\"//g' )
  elif [[ "${OSTYPE}" == 'darwin15' ]]; then
    stored_cs_raw=$(xattr -p "${attrib_key}" "${input_file}" 2>/dev/null )
    stored_cs="${stored_cs_raw}"
  elif [[ "${OSTYPE}" == 'freebsd10.3' ]]; then
    stored_cs_raw=$(getextattr -q user "${attrib_key}" -p "${attrib_key}" "${input_file}" 2>/dev/null )
    stored_cs="${stored_cs_raw}"
  fi
  echo "${stored_cs}"
}

function write_checksum {
  checksum="$1"
  input_file="$2"
  if [[ "${OSTYPE}" == 'linux-gnu' ]]; then
    stored_cs_raw=$(setfattr -n "${attrib_key}" -v "${checksum}" "${input_file}")
  elif [[ "${OSTYPE}" == 'darwin15' ]]; then
    xattr -w "${attrib_key}" "${checksum}" "${input_file}" 2>/dev/null
  elif [[ "${OSTYPE}" == 'freebsd10.3' ]]; then
    stored_cs_raw=$(getextattr -q user "integ.${digest}" -p "${attrib_key}" "${input_file}" 2>/dev/null )
  fi
  return $?
}

function remove_checksum {
  input_file="$1"
  if [[ "${OSTYPE}" == 'linux-gnu' ]]; then
    setfattr -x "${attrib_key}" "${input_file}" 2>/dev/null
  elif [[ "${OSTYPE}" == 'darwin15' ]]; then
    xattr -d "${attrib_key}" "${input_file}" 2>/dev/null
  elif [[ "${OSTYPE}" == 'freebsd10.3' ]]; then
    stored_cs_raw=$(getextattr -q user "integ.${digest}" -p "${attrib_key}" "${input_file}" 2>/dev/null )
    stored_cs="${stored_cs_raw}"
  fi
  return $?
}

# Set Default Options
verbose=0
digest='sha1'
action='read'

OPTIND=1
while getopts "vh?wrdf:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    w)  action='write'
        ;;
    d)  action='delete'
        ;;
    v)  verbose='1'
        ;;
    f)  digest="${OPTARG}"
        ;;
    esac
done

shift "$((OPTIND-1))" # Shift off the options and optional --.

# Set the attribute
attrib_key="integ.${digest}"
if [[ "${OSTYPE}" == 'linux-gnu' ]]; then
  attrib_key="user.${attrib_key}"
fi

for filename in "$@"
do

# Generate the checksum for the file, we always need this

if [ "${action}" == 'write' ]; then
  #--------------------------------------
  # Add new checksum
  #--------------------------------------
  # This code assumes that it is not worth;
  #   reading any existing checksum,
  #   calculating the current checksum
  #   comparing
  #   only writing a new one if it's difference
  # If the read access of a device is *significantly* faster than a write, it
  # may be more efficient to read any current checksum first to save a potential
  # write. This code does not assume this.
  # Algorithm:
  #  Calculate the current checksum
  #  Write it to the file attribute
  #  Read the checksum from disk and compare to in memory calculated one, this
  #   ensures the attribute was written to disk ok

  # Calculate the current checksum
  file_calc_checksum=$(generate_checksum "${digest}" "${filename}")

  # Write the checksum to disk
  write_checksum "${file_calc_checksum}" "${filename}"
  ret=$?
  if [ "$ret" -eq "0" ]; then
    file_current_checksum=$(read_checksum "${filename}")
    if [ "${file_calc_checksum}" == "${file_current_checksum}" ]; then
      echo "${filename} : ${file_calc_checksum}"
    else
      echo "Calculated checksum and filesystem read checksum differ!" 1>&2
      echo "${filename} : disk; ${file_current_checksum} : calc; ${file_calc_checksum}" 1>&2
      exit 4
    fi
  else
    echo "Error writing checksum to attribute" 1>&2
    exit 2
  fi
fi

if [ "$action" == 'delete' ]; then
 remove_checksum "${filename}"
 file_current_checksum=$(read_checksum "${filename}")
 if [ "${file_current_checksum}" == "" ]; then
   # We don't have any checksum
   echo "${filename} : <removed>"
 else
   echo "Failed to remove checksum" 1>&2
 fi
fi

if [ "$action" == 'read' ]; then
  # Check if checksum stored and correct, report
  # Get any current checksum
  file_current_checksum=$(read_checksum "${filename}")
  if [ "${file_current_checksum}" == "" ]; then
    # We don't have any checksum
    echo "${filename} : <none>"
  else
    file_calc_checksum=$(generate_checksum "${digest}" "${filename}")
    if [ "${file_calc_checksum}" == "${file_current_checksum}" ]; then
      echo -n "${filename} : pass"
      if [ "$verbose" -gt "0" ]; then
        echo -n " : ${file_calc_checksum}"
      fi
      echo
    else
      if [ "$verbose" -gt "0" ]; then
        echo "${filename} : disk; ${file_current_checksum} : calc; ${file_calc_checksum}" 1>&2
      else
        echo "${filename} : fail" 1>&2
      fi
      exit 4
    fi
  fi
fi

done
