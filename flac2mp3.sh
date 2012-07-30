#!/bin/bash

ls | while read ARQ; do

	flac -cd "${ARQ}" | lame -h - "MP3/${ARQ}.mp3"; done

done	

