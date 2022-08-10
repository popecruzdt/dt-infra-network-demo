#!/bin/bash

# The default amount of delay to induce
DELAY=0ms
LOSS=0%
RATE=10000mbit

while getopts d:l:r: flag
do
    case "${flag}" in
        d) DELAY=${OPTARG};;
        l) LOSS=${OPTARG};;
        r) RATE=${OPTARG};;
    esac
done

# linux traffic control binary
TC=/sbin/tc

# interface traffic will leave on
IF=eth0

# Destination CIDR
VPC=172.31.0.0/16
#aws-et-ubuntu-01
DST_CIDR1=172.31.63.48/32
#aws-et-ubuntu-04
DST_CIDR2=172.31.63.127/32
#aws-tpc-jump-amazonlinux-02
DST_CIDR3=172.31.93.252/32

# filter command -- add ip dst match at the end
U32="$TC filter add dev $IF protocol ip parent 1:0 prio 3 u32"

create () {
  echo "== SHAPING INIT =="

  # create the root qdisc
  $TC qdisc add dev $IF root handle 1: prio

  # create the modified qdisc with netem delay
  $TC qdisc add dev $IF parent 1:3 handle 30: netem delay $DELAY loss $LOSS

  # create the child qdisc with bandwidth rate limiting
  # $TC qdisc add dev $IF parent 30: handle 50: tbf rate $RATE buffer 1600 limit 3000

  # setup filter to restrict modified qdisc
  $U32 match ip dst $DST_CIDR1 flowid 1:3
  $U32 match ip dst $DST_CIDR2 flowid 1:3
  $U32 match ip dst $DST_CIDR3 flowid 1:3

  echo "== SHAPING DONE =="
}

# run clean to ensure existing tc is not configured
clean () {
  echo "== CLEAN INIT =="
  $TC qdisc del dev $IF root
  echo "== CLEAN DONE =="
}

clean
create
