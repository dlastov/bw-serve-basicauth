# bw-serve-basicauth

Exposes [Vault Management API](https://bitwarden.com/help/vault-management-api/), implemented by
[bw serve](https://bitwarden.com/help/cli/) command, through
[Nginx reverse proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/), adding a need of
[basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
to the HTTP requests. 


## Starting

`BW_SERVER_URL` is optional, `https://vault.bitwarden.com` is the default.

`NGINX_USER` and `NGINX_PASSWORD` is the user/password that will be expected in HTTP requests.
When not specified, so `BW_CLIENTID` and `BW_CLIENTSECRET` will be used in their place.

`BW_PASSWORD` is optional. When specified, the vault will be unlocked. Otherwise, it can be unlocked later, using the API.

```shell
sudo docker run \
--env BW_SERVER_URL="https://vault.bitwarden.com" \
--env BW_CLIENTID="user.12345678-9012-3456-7890-1234567890123" \
--env BW_CLIENTSECRET="12345678901234567890" \
--env BW_PASSWORD="12345" \
--env NGINX_USER="basicauth_user" \
--env NGINX_PASSWORD="basicauth_pass" \
--publish 8080:80 \
--detach \
-it dlast0v/bw-serve-basicauth:1.0.0
```

## Querying

The difference from using `bw serve` directly is that basic auth user and password has to be provided. I assume that
Nginx also sanitises the requests.

```shell
curl -X GET -u "basicauth_user:basicauth_pass" -H 'Content-Type: application/json' http://localhost:8080/list/object/items
```

## Debugging

Attach the `bash` argument to enter the terminal:
```shell
sudo docker run \
--env BW_SERVER_URL="https://vault.bitwarden.com" \
--env BW_CLIENTID="user.12345678-9012-3456-7890-1234567890123" \
--env BW_CLIENTSECRET="12345678901234567890" \
--env BW_PASSWORD="12345" \
--env NGINX_USER="basicauth_user" \
--env NGINX_PASSWORD="basicauth_pass" \
--publish 8080:80 \
-it dlast0v/bw-serve-basicauth:1.0.0 bash
```

Then you can run e.g.
```shell
/root/entrypoint.sh &
tail -f /var/log/nginx/access.log
```

## Building the image

```shell
cd docker/bw-serve-basicauth
sudo docker build --tag "dlast0v/bw-serve-basicauth:1.0.0" .
sudo docker image tag "dlast0v/bw-serve-basicauth:1.0.0" "dlast0v/bw-serve-basicauth:latest"
sudo docker push dlast0v/bw-serve-basicauth:1.0.0
```
