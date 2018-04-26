# Changelog

## 0.4.0

- Fix deprecated API use.
- Fix header wrapping in requests.

## 0.3.1

- Added http proxy option to the console client.

## 0.3.0

- Removed dependency on `http` package.

## 0.2.2

- Add executor support to rate-limit the clients.

## 0.2.1

- Add curl support.

## 0.2.0

**Breaking changes**:

- instead of exporting the `http` package, `http_client` provides its own API
  - *console* and *browser* clients continue to use the `http` package
  - preparation to support [node_io](https://github.com/dglogik/node_io.dart)
    for apps that want to be packaged as a single binary (e.g. `.exe`)
  - preparation to support the Fetch API (e.g. in service workers)

- removed the awkward `newHttpClient()` methods.

## 0.1.0

- Exporting classes from the `http` package (version: `^0.1.13`).

### 0.1.0+1

- Exporting streaming request and response.
