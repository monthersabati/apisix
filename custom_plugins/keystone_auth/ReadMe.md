# Keystone Token Validator Plugin for APISIX

## Introduction

The Keystone token validator plugin is a custom plugin for APISIX that validates tokens sent in a configurable header (defaulting to `X-Auth-Token`) by calling the Keystone service. Upon successful validation, it sends the identity information in a configurable header (defaulting to `X-Identity`) to the backend.

## Plugin Configuration Options

The plugin requires the following configuration parameters:

* `keystone_endpoint`: The URL of the Keystone service. (Required)
* `timeout`: The timeout in milliseconds for the request to Keystone. (Optional, default: 5000)
* `auth_header_name`: The name of the header of incoming request that will contain the token. (Optional, default: `X-Auth-Token`)

* `identity_header_name`: The name of the header to be inserted that will contain the identity information. (Optional, default: `X-Identity`)

## Deployment Steps

### APISIX

1. Copy the `keystone-auth.lua` file to `/path/to/apisix-api-gw/apisix/plugins/keystone-auth.lua`.
2. Add `keystone-auth` to the `plugins` section in `/path/to/apisix-api-gw/conf/config.yaml`.
3. Restart the APISIX service.

### APISIX Dashboard

1. Download the updated schema from `curl 127.0.0.1:9090/v1/schema | jq > schema.json`.
2. Copy the `schema.json` file to `/path/to/apisix-dashboard/conf/`.
3. Add the plugin name to the `/path/to/apisix-dashboard/conf/conf.yaml` file.
4. Restart the APISIX Dashboard service.

## Usage Example

After deploying the plugin, you can use it in the APISIX Dashboard like other plugins. Configure the plugin with your Keystone endpoint and other optional parameters as needed.

When a request is made with a valid auth_header_name (`X-Auth-Token`) header, the plugin will validate the token with Keystone and forward the identity information in the configured header to the backend.
