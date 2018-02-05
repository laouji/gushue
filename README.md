# gushue

a small debug script that parses a log of receipts, and sends a request to Apple verification service

## Usage

```
./gushue.pl logfile.log | jq .
```

## Log Format

for now it just assumes this log format:

```
hostname 2017/12/18 12:00:42.436948 some kind of log message [.* rcpt:<receipt here>.*]
```

## Notes

named after curling champion Brad Gushue since this saves me from copy and pasting and using curl (harhar) by hand

![gushue](https://user-images.githubusercontent.com/2435916/35831014-86b8a6c6-0ac8-11e8-8f48-74d426ba7d15.jpg)
