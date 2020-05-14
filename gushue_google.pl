#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;
use Furl;
use HTTP::Request;
use HTML::Entities;
use IO::File;
use IO::Socket::SSL;
use JSON::XS qw/encode_json decode_json/;
use JSON::WebToken;

my $http_client = Furl->new();

my ($package_name, $log_filename, $settings_filename) = @ARGV;
if (!$package_name || !$log_filename || !$settings_filename) {
  print "required arguments: package_name log_filename settings_filename\n";
  exit(2);
}

my $json_settings = read_file($settings_filename);

my ($auth_info, $auth_err) = get_auth_token();
if ($auth_err ne "") {
  printf("failed to make auth request: %s", $auth_err);
  exit(1);
}

my ($product_list, $list_err) = list_products($auth_info, $package_name);
if ($auth_err ne "") {
  printf("failed to fetch products: %s", $list_err);
  exit(1);
}

# remap the array into a hashmap to make it easier to find stuff by the sku
my $products = {};
for my $product (@$product_list) {
  my $sku = $product->{sku};
  $products->{$sku} = {"status" => $product->{status}, "purchase_type" => $product->{purchaseType}};
}

my $i = 0;
my $fh = IO::File->new("< ${log_filename}");
if (defined $fh) {
  while (defined(my $line = $fh->getline)) {
    $i++;
    my ($product_id, $gps_token) = parse_logline($line);
    if (!$product_id) {
      warn sprintf("problem parsing log line %d: no matches found", $i);
      next;
    }

    if (!exists $products->{$product_id}) {
      warn sprintf("warning for log line %d: %s is not a valid sku", $i $product_id);
    }

    my ($res, $err) = verify_purchase($auth_info, $package_name, $product_id, $gps_token);
    if ($err ne "") {
      warn sprintf("encountered error at log line %d: %s", $i, $err);
      next;
    }
    print $res . "\n";
  }
$fh->close;
}

sub parse_logline {
  my $logline = shift;
  if ($logline =~ /^[a-z0-9\-]*+\s\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\.\d+.*\[.*gps_product_id\:\[(.*)\] gps_token\:\[(.*)\] sdk/) {
    return $1, $2;
  }
  return "", "";
}

sub get_auth_token {
  my $uri = 'https://accounts.google.com/o/oauth2/token';
  my $http_client = Furl->new();
  my $header  = ['Content-Type' => 'application/x-www-form-urlencoded'];
  my $body  = 'grant_type=' . get_encoded_entities() . '&assertion=' . get_jwt();

  my $req = HTTP::Request->new("POST", $uri, $header, $body);
  my $res = $http_client->request($req, scheme => "https");

  unless ($res->is_success) {
    print $res->body;
    return "", "auth request returned error: " . $res->status_line;
  }
  return decode_json($res->decoded_content), ""
}

sub authorized_request {
  my ($auth_info, $uri) = @_;

  my $header  = ['Authorization' => sprintf("%s %s", $auth_info->{token_type}, $auth_info->{access_token})];
  my $req = HTTP::Request->new("GET", $uri, $header);
  my $res = $http_client->request($req, scheme => "https");
  
  unless ($res->is_success) {
    print $res->body;
    return "", sprintf("req to %s returned error: %s", $uri, $res->status_line);
  }
  return $res->decoded_content, ""
}

# TODO implement subscription endpoint if needed
# my $uri = sprintf("https://www.googleapis.com/androidpublisher/v3/applications/%s/purchases/subscriptions/%s/tokens/%s",
sub verify_purchase {
  my ($auth_info, $package_name, $product_id, $purchase_token) = @_;

  my $uri = sprintf("https://www.googleapis.com/androidpublisher/v3/applications/%s/purchases/products/%s/tokens/%s",
    $package_name,
    $product_id,
    $purchase_token,
  );
  return authorized_request($auth_info, $uri);
}

sub list_products {
  my ($auth_info, $package_name) = @_;

  my $uri = sprintf("https://www.googleapis.com/androidpublisher/v3/applications/%s/inappproducts",
    $package_name,
  );
  my ($content, $err) = authorized_request($auth_info, $uri);
  if ($err ne "") {
    return "", $err;
  }
  return decode_json($content)->{inappproduct}, ""
}

sub get_jwt {
  my $now = time;
  my $settings = decode_json($json_settings);
  return JSON::WebToken->encode({
    iss   => $settings->{client_email},
    scope => "https://www.googleapis.com/auth/androidpublisher",
    aud   => "https://accounts.google.com/o/oauth2/token",
    exp   => $now + 3600,
    iat   => $now,
  }, $settings->{private_key}, 'RS256', {typ => 'JWT'});
}

sub get_encoded_entities {
  return encode_entities('urn:ietf:params:oauth:grant-type:jwt-bearer');
}
