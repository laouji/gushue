# gushue

debug scripts that parase logs of receipts, and sends a request to Apple or Google's purchase verification services

## Usage

### Apple

#### Running the command

```
$ ./gushue.pl logFile | jq.
```

##### Params

param name | description
--- | ---
logFile | some file containing loglines that match the format outlined in the Log Format section below

##### Output

running the command will output lines of json representing the response body as outlined by [Apple's developer API docs](https://developer.apple.com/documentation/appstorereceipts/responsebody)

```
{
  "receipt": {
    "receipt_type": "Production",
    "adam_id": 1111111111,
    "app_item_id": 1234567890,
    "bundle_id": "com.some.thing",
    "application_version": "1.11.111",
    "download_id": 22222222222222,
    "version_external_identifier": 333333333,
    "receipt_creation_date": "2020-01-03 17:30:27 Etc/GMT",
    "receipt_creation_date_ms": "1578072627000",
    "receipt_creation_date_pst": "2020-01-03 09:30:27 America/Los_Angeles",
    "request_date": "2020-05-14 14:20:52 Etc/GMT",
    "request_date_ms": "1589466052440",
    "request_date_pst": "2020-05-14 07:20:52 America/Los_Angeles",
    "original_purchase_date": "2017-12-27 15:50:44 Etc/GMT",
    "original_purchase_date_ms": "1514389844000",
    "original_purchase_date_pst": "2017-12-27 07:50:44 America/Los_Angeles",
    "original_application_version": "1.0.00",
    "in_app": [
      {
        "quantity": "1",
        "product_id": "com.some.app.item_bundle.product_id",
        "transaction_id": "999999999999999",
        "original_transaction_id": "888888888888888",
        "purchase_date": "2020-01-03 17:30:03 Etc/GMT",
        "purchase_date_ms": "1578072603000",
        "purchase_date_pst": "2020-01-03 09:30:03 America/Los_Angeles",
        "original_purchase_date": "2020-01-03 17:30:03 Etc/GMT",
        "original_purchase_date_ms": "1578072603000",
        "original_purchase_date_pst": "2020-01-03 09:30:03 America/Los_Angeles",
        "is_trial_period": "false"
      }
    ]
  },
  "status": 0,
  "environment": "Production"
}
```

#### Log Format

for now it just assumes this log format:

```
hostname 2017/12/18 12:00:42.436948 some kind of log message [.*rcpt:<receipt here>.*]
```

### Google

Makes a request against Google's [Purchases.products API](https://developers.google.com/android-publisher/api-ref/purchases/products/get)

#### Running the command

```
$ ./gushue_google.pl packageName logFile certificateFile
```

param name | description
--- | ---
packageName | as defined in Google Play Store, such as `com.some.thing`
logFile | some file containing loglines that match the format outlined in the Log Format section below
certificateFile | a json file containing fields outlined in the Credentials Format section below

##### Output

running the command will output lines of json representing the ProductPurchase resource as outlined by [Google's developer API docs](https://developers.google.com/android-publisher/api-ref/purchases/products#resource)

```
{
  "purchaseTimeMillis": "1575148122801",
  "purchaseState": 0,
  "consumptionState": 0,
  "developerPayload": "",
  "acknowledgementState": 1,
  "kind": "androidpublisher#productPurchase"
}
```

#### Log Format

for now it just assumes this log format:

```
hostname 2017/12/18 12:00:42.436948 some kind of log message [.*gps_product_id\:<productId> gps_token:<token>]
```

### Credentials Format

a JSON entity containing at least the following keys:

```
{
  "private_key": "-----BEGIN PRIVATE KEY-----\ncontentsoftheprivatekeygohere=\n----- END PRIVATE KEY-----\n",
  "client_email": "some-user@api-4444444444444444444-222222.iam.gserviceaccount.com",
}
```

where both the private key and client email are registered with the Google Play Developer API

## Notes

named after curling champion Brad Gushue since this saves me from copy pasting and curling all the needed requests by hand

![gushue](https://user-images.githubusercontent.com/2435916/35831014-86b8a6c6-0ac8-11e8-8f48-74d426ba7d15.jpg)
