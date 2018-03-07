#!/usr/bin/env perl
use strict;
use warnings;
use Furl;
use HTTP::Request;
use IO::File;
use IO::Socket::SSL;
use JSON::XS qw/encode_json/;

my $filename = $ARGV[0];
if (!$filename) {
  print "filename must be passed as an argument\n";
  exit(2);
}

my $i = 0;

my $fh = IO::File->new("< ${filename}");
if (defined $fh) {
  while (defined(my $line = $fh->getline)) {
    $i++;
    my $receipt = parse_logline($line);
    if (!$receipt) {
      warn sprintf("problem parsing line %d: no matches found", $i);
      next;
    }

    my ($res, $err) = verify($receipt);
    if ($err ne "") {
      warn sprintf("encountered error at line %d: %s", $i, $err);
      next;
    }
    print $res . "\n";
  }
$fh->close;
}

sub parse_logline {
  my $logline = shift;
  if ($logline =~ /^[a-z0-9\-]*+\s\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\.\d+.*\[.*rcpt\:(.*)\s.*\]/) {
    return $1;
  }
  return "";
}

sub verify {
  my $receipt = shift;

  my $uri     = "https://buy.itunes.apple.com/verifyReceipt";
  #my $uri     = "https://sandbox.itunes.apple.com/verifyReceipt";
  my $header  = ['Content-Type' => 'application/json; charset=UTF-8'];
  my $content = encode_json {"receipt-data" => $receipt};

  my $http_client = Furl->new();

  my $req = HTTP::Request->new("POST", $uri, $header, $content);
  my $res = $http_client->request($req, scheme => "https");

  unless ($res->is_success) {
    return "", "verification returned error: " . $res->status_line;
  }
  return $res->decoded_content, ""
}

