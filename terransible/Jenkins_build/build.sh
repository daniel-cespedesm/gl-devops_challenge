#!/bin/bash

docker image build -t dacesmo/jenkins .
docker login
docker image push dacesmo/jenkins
