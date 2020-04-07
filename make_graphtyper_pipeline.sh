#!/usr/bin/env bash

set -e
set -o pipefail

bam=$1
CONFIG=$2
jobId=$3

if [[ -z "$bam" ]]
then
  echo "Usage: run.sh <BAM/bamlist> [CONFIG] [JOBID]"
  exit 1
fi

TOP_DIR="$(realpath $(dirname ${BASH_SOURCE[0]}))"

if [[ -z "$CONFIG" ]]
then
  CONFIG=config.sh
fi

if [[ -z "$jobId" ]]
then
  jobId="default"
fi

source $CONFIG


if [[ ! -z $REGION_START ]]
then
  # Call only a single region
  echo "./node_script.sh $CONFIG $bam $REGION_START $jobId"
elif [[ ! -z $REGION_FILE ]] && [[ -f $REGION_FILE ]]
then
  for region in `cat $REGION_FILE`
  do
    echo "./node_script.sh $CONFIG $bam $region $jobId"
  done
else
  for chrom in $CHROMOSOMES
  do
    start=1
    end=$((start - 1 + REGION_SIZE))
    CHROM_SIZE=`grep -w "^${chrom}" $GENOME.fai | cut -f2`
    end=$((end>CHROM_SIZE?CHROM_SIZE:end)) # Never expand end further than the total length of the chromosome

    while [[ $start -lt $CHROM_SIZE ]]
    do
      region_id=`printf "%09d" $start`"-"`printf "%09d" $end`

      # Only add this region if the output file is missing
      if [[ ! -f "results/${chrom}/${region_id}.vcf.gz" ]]; then
        echo "./node_script.sh $CONFIG $bam ${chrom}:${start} $jobId"
      fi

      start=$((end + 1))
      end=$((start - 1 + REGION_SIZE))
      end=$((end>CHROM_SIZE?CHROM_SIZE:end)) # Never expand end further than the total length of the chromosome
    done
  done
fi
