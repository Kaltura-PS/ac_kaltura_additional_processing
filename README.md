# ac_kaltura_additional_processing
Additional processing for content migrated from Adobe Connect

## General flow ##
Download recording files and, if possible, retrieve hosts list, web links and related files from recording XML files


## Pre-requisites
- This script assumes that the executer previously used the https://github.com/kaltura/adobe-connect-to-mkv-to-kaltura process to ingest Adobe Connect recordings and the environment is preconfigured with this repo's requirements.
- cURL CLI
- unzip
- xvfb
- pidof [provided by the `sysvinit-utils` package in Debian/Ubuntu and by `sysvinit-tools` in RHEL/CentOS/FC]
- Ruby [2.3 and 2.5 were tested]
- Ruby Gems: `adobe_connect`, `kaltura-client`, `nokogiri` `logger`

## Running

Once ready, run:

```sh
$ ./additional_processing_wrapper.sh </path/to/asset/list/csv>
```

Where `</path/to/asset/list/csv>` is the path to a CSV file in the following format:

kaltura_entry_id,sco_id,recording_id
