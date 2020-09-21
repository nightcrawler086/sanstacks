#!/usr/bin/env python3

import argparse
import json
import requests

## TODO ##
#
# - Argument processing
# - get function
# - post function
# - monitor function
# - 

parser = argparse.ArgumentParser()
parser.add_argument("--build")
parser.add_argument("--count")
parser.add_argument("--type")
parser.add_argument("--soeid")
parser.add_argument("--chef-scripts")

parser.parse_args()
# Variable definitions
api_url='https://deadpool.namdev.nsrootdev.net/cgi-bin/API_deadpool.py'


# Functions
def get(url, **kwargs):


def post(url, **kwargs):


def validate(url, build, **kwargs): 
