# What's this?

1. You are running nginx behind Cloudflare CDN
2. Your want to get the real IP address of client, but not the cloudflare's server ips
3. By configuring your nginx.conf, you can use `real_ip_header CF-Connecting-IP; ` to solve this.

# What's the difference from Mamadou Babaei's original version

The orginal script did not verify the file download from cloudflare `https://www.cloudflare.com/ips-v4` and `https://www.cloudflare.com/ips-v6`. This new script add IPv4 and IPv6 verification logic. It helps to prevent from wrong data when cloudflare official web site or your nginx server itself has any problem.

# Main procedure

## Create cloudflare ips file path

```bash
sudo mkdir /etc/nginx/cloudflare
```

## Create cloudflare ips sync script

```bash
vi /etc/nginx/cloudflare/cloudflare-ip-ranges-updater.sh
```

## Execute cloudflare ips sync script.
```bash
chmod +x /etc/nginx/cloudflare/cloudflare-ip-ranges-updater.sh
/etc/nginx/cloudflare/cloudflare-ip-ranges-updater.sh

```

## Review cloudflare ips file content
```vb
# CloudFlare IP Ranges
# Generated at Sun Nov 13 15:19:34 UTC 2022 by /etc/nginx/cloudflare/cloudflare-ip-ranges-updater.sh

set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;

set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 2803:f800::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2405:8100::/32;
set_real_ip_from 2a06:98c0::/29;
set_real_ip_from 2c0f:f248::/32;

real_ip_header CF-Connecting-IP;
```


## Change Nginx configuration to include cloudflare ips

edit nginx configuration file `/etc/nginx/nginx.conf`, add contents below to `http{}` block.

```ini
http {
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    ##
    # Gzip Settings
    ##
    gzip on;
    # ...

    # Add this line
    include /etc/nginx/cloudflare/cloudflare-ips;
    
    
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
    #...

}

```

## Verify and Reload nginx configuration

```bash
sudo nginx -t
sudo nginx -s reload
```

## Check Nginx access log

Check Nginx access log, you will find Cloudflare server IP address has been replaced by client real IP address.

```bash
tail -f /var/log/nginx/access.log

#213.128.5.228 - - [13/Nov/2022:15:55:01 +0000] "GET / HTTP/1.1" 200 14 "-" "curl/7.85.0"
#128.160.32.21 - - [13/Nov/2022:15:55:01 +0000] "GET / HTTP/1.1" 200 13 "-" "curl/7.79.1"


```

# Reference
- [Module ngx_http_realip_module](http://nginx.org/en/docs/http/ngx_http_realip_module.html)
- [Getting real IP addresses using Nginx and CloudFlare](https://www.babaei.net/blog/getting-real-ip-addresses-using-nginx-and-cloudflare/)
- [Getting Real IP Addresses Using CloudFlare, Nginx, and Varnish](https://danielmiessler.com/blog/getting-real-ip-addresses-using-cloudflare-nginx-and-varnish/)