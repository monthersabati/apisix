local plugin_name = 'keystone-auth'

local core = require('apisix.core')
local http = require('resty.http')
local cjson = require('cjson.safe')

local schema = {
     type = 'object',
     properties = {
          keystone_endpoint = {
               type = 'string'
          },
          timeout = {
               type = 'integer',
               default = 5000,
          },
          auth_header_name = {
               type = 'string',
               default = "X-Auth-Token",
          },
          identity_header_name = {
               type = 'string',
               default = "X-Identity",
          },
          
     },
     required = { 'keystone_endpoint' },
}

local _M = {
    version = 1.0,
    priority = 99,
    name = plugin_name,
    schema = schema
}

-- Function to validate the plugin configuration schema
function _M.check_schema(conf)
     return core.schema.check(schema, conf)
end

-- Function to validate the token with Keystone
local function validate_token(conf, token)
    local httpc = http.new()
    httpc:set_timeout(conf.timeout)  -- set timeout to 5 seconds
    
    local keystone_url = conf.keystone_endpoint .. '/v3/auth/tokens'
    local res, err = httpc:request_uri(keystone_url, {
         method = 'GET',
         headers = {
              ['X-Auth-Token'] = token,
              ['X-Subject-Token'] = token,
         }
    })
    
    if not res then
         ngx.log(ngx.ERR, 'Failed to call Keystone service: ', err)
         return nil, 'Failed to validate token: ' .. (err or 'unknown error')
    end

    if res.status ~= 200 then
         ngx.log(ngx.ERR, 'Token validation failed. HTTP status: ', res.status)
         return nil, 'Invalid token'
    end

    -- Decode the JSON response
    local body, err = cjson.decode(res.body)
    if not body then
         ngx.log(ngx.ERR, 'Failed to decode Keystone response: ', err)
         return nil, 'Failed to decode token info'
    end

    local token_info = body.token
    if not token_info then
         ngx.log(ngx.ERR, 'Token info missing in Keystone response')
         return nil, 'Token info missing in response'
    end

    return token_info, nil
end

-- Main access function for the plugin
function _M.access(conf, ctx)
    -- Extract the conf.auth_header_name from the request headers
    local headers = ngx.req.get_headers()
    local auth_header_name = conf.auth_header_name
    local token = headers[auth_header_name]
    if not token then
        ngx.log(ngx.ERR, 'Missing ' .. auth_header_name .. ' header')
        return core.response.exit(403, { message = 'Missing ' .. auth_header_name .. ' header' })
    end

    -- Validate the token
    local token_info, err = validate_token(conf, token)
    if not token_info then
        return core.response.exit(403, { message = err })
    end

    -- Encode the token info as a JSON string then base64 encode it
    local token_info_json = cjson.encode(token_info)
    local token_info_b64 = ngx.encode_base64(token_info_json)

    -- Set the X-Identity-Info header for the upstream request
    local identity_header_name = conf.identity_header_name
    ngx.req.set_header(identity_header_name, token_info_b64)
    
    ngx.log(ngx.INFO, 'Successfully validated token and set ' .. identity_header_name .. ' header')
end

return _M
