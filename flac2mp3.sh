#!/bin/bash
#
# Simple script to convert FLAC music files to mp3 format

ls | while read ARQ; do

	flac -cd "${ARQ}" | lame -h - "MP3/${ARQ}.mp3"; done

done	

