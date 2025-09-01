#!/bin/bash


# Build temporary Docker image needed later by bunny
docker build -f Dockerfile -t dirlister-rootfs:latest .

# Build OCI image for urunc
docker build -f bunnyfile -t dirlister:latest .
