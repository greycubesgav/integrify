# integrify
Shell script which stores a digest of a file's content within it's extended attributes.

```
Usage: integrify [OPTIONS] FILE
Check the integrity checksum file attribute and optionally add the checksum

Option  Meaning
  -c    Check the checksum of FILE
  -a    Add a new checksum to FILE
  -s    When adding new checksums skip if the file already has checksum data
  -d    Remove the checksum from FILE
  -l    List files checksums as per a shasum output
  -f    Set the digest function to write, default 'sha1'
  -v    Verbose messages

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
## Benefits

* Unlike an external .sfv file, the checksum data is stored along with the file metadata meaning individual files can be moved between directories, or
even copied between servers (using a tool such as rsync) and the checksum data remains.

* Changes to timestamp data such as created date, modified date, do not effect the checksum data

## Usage

### Adding integrify data to a file
    integrify -a data_01.dat

### Checking the integrity of a file with integrify data
    integrify -c data_01.dat

### Checking the integrity of a file with integrify data verbosely
    integrify -c -v data_01.dat

### Listing integrify data as shasum command output
    integrify -l data_01.dat

### Using shasum to check the integrity of a list of files (osx)
    integrify -l data_01.dat | shasum -c

### Recursive Commands

### Recursively add integrify data to all files within a directory structure
    find directory -type f -print0  | xargs -0 integrify -a

### Recursively list the checksums as shasum output (osx)
    find directory -type f -print0  | xargs -0 integrify -l

### Locate duplicate files within a directory structure (osx)
    integrify_dupes directory

### Transfering a file to a remote machine maintainig integrify metadata
    rsync -X data_01.dat remote_server:/destination/

## Use Cases

### Digital Photography - Corrupt Photo Detection

1. RAW image files are copied from the camera to disk
2. Integrify checksums are added to the file after copying
3. One of the files becomes corrupt through underlaying disk failure.

#### Identify the corrupt file

    integrify -c *.NEF
    _D600023.NEF : OK
    _D600024.NEF : OK
    _D600025.NEF : FAILED
    _D600026.NEF : OK

### Digital Photography - Corrupt Backup Detection

Assuming that some photos are stored on a primary drive and some photos are stored on an archive drive.

The backup drive begins to fail resulting in read errors. No integrity data has been stored with the files so it is not possible to detect which images are corrupted on the archive drive without trying to open the files and seeing if they can be read and if the 'look' ok.

Some of these images are also stored on a primary drive which is assumed to be correct.

Both the primary and archive drive together provide a master copy of all files.

### Locating Duplicate Files

As the integrity data is stored along with the files, reading this data is 'cheap', so a comparing each file's integrity data across a large volume of files is faster than generating new checksums for the purpose, or maniputlating multiple shasum files.

#### Indentify duplicate files within a diretory structure
  find directory -print0  | xargs -0 integrify -l | sort


## To Do

* Test against complicated file naming, including unicode characters
* Use the digest data stored within the integrify metadata to verify the file (currently SHA1 is assumed)
