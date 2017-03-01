# integrify
Shell script which stores a digest of a file's content within it's extended attributes.

```
Usage: integrify [OPTIONS] FILE
Check the integrity checksum file attribute and optionally add the checksum

Option  Meaning
  -c     Check the checksum
  -a     Add a new checksum to FILE
  -d     Remove the checksum from FILE
  -l     List files checksums as per a sfv file
  -f     Set the digest function to write, default 'sha1'
  -v     Verbose messages

Examples:
   Check a file's integrity checksum
     integrify myfile.jpg

   Add a new checksum to a file
     integrify -w myfile.jpg

Info:
  When copying files, extended attributes should be preserved to ensure integrity data is copied.
  e.g. rsync -X source destination
       osx : cp -p source destination
```
