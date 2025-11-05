#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/
#-------------------------------------------------------------------------------
# Create a docker image for silicon compiler
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2025
#-------------------------------------------------------------------------------
use v5.38;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);

my $repo    = q(silicon_compiler__docker_image);                                # Repo
my $user    = q(philiprbrenan);                                                 # User
my $home    = fpd q(/home/phil/sc/), $repo;                                     # Home folder
my $wf      = q(.github/workflows/run.yml);                                     # Work flow on Ubuntu
my $shaFile = fpe $home, q(sha);                                                # Sh256 file sums for each known file to detect changes
my @ext     = qw(.pl .py .txt .md);                                             # Extensions of files to upload to github

say STDERR timeStamp,  " Push to github $repo";

my @files = searchDirectoryTreesForMatchingFiles($home, @ext);                  # Files to upload
   @files = changedFiles $shaFile, @files;                                      # Filter out files that have not changed

if (!@files)                                                                    # No new files
 {say "Everything up to date";
  exit;
 }

if  (1)                                                                         # Upload via github crud
 {for my $s(@files)                                                             # Upload each selected file
   {my $c = readBinaryFile $s;                                                  # Load file

    $c = expandWellKnownWordsAsUrlsInMdFormat $c if $s =~ m(README);            # Expand README

    my $t = swapFilePrefix $s, $home;                                           # File on github
    my $w = writeFileUsingSavedToken($user, $repo, $t, $c);                     # Write file into github
    lll "$w  $t";
   }
 }

my $dt    = dateTimeStamp;
my $yml   = <<"END";                                                            # Create workflow
# Test $dt
name: Build and Push Docker Image
run-name: $repo

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: \${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-22.04

    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout\@v4

      - name: Log in to GitHub Container Registry
        uses: docker/login-action\@v3
        with:
          registry: \${{ env.REGISTRY }}
          username: \${{ github.actor }}
          password: \${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action\@v3

      - name: Build and push Docker image
        uses: docker/build-push-action\@v6
        with:
          context: .
          file: ./Dockerfile.txt
          push: true
          tags: |
            \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}:latest
            \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}:\${{ github.sha }}
END

my $f = writeFileUsingSavedToken $user, $repo, $wf, $yml;                       # Upload workflow
lll "$f  Ubuntu work flow for $repo";
