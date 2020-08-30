---
title: "Step by step howto: VyOS OpenVPN Tunnel (VyOS to VyOS)"
layout: single
classes: wide
date: 2019-12-15 18:26 +100
categories:
  - vyos
  - openvpn
  - step-by-step
---
As i am going to run my "infrastructure" (a collection of virtual machines running docker and other stuff) in
two locations i want to run a VPN tunnel between those sites to connect them securely and access the infrastructure. I am using [VyOS](http://www.vyos.io/) firewalls and in this step-by-step guide i describe
how i set up the site to site tunnel between the two firewalls.

On the firewall that acts as a server for [OpenVPN](https://openvpn.net/download-open-vpn/) i use [Easy-RSA 3](https://github.com/OpenVPN/easy-rsa) ([Easy-RSA 3 Documentation](https://easy-rsa.readthedocs.io/en/latest/)).

### Setup Easy-RSA 3:

```terminal
cd /config/auth/EasyRSA-v3.0.6
./easyrsa init-pki
./easyrsa build-ca
```

You need to set a common name for your CA as well as a passphrase.

Result:

```terminal
vyos@vyos:~$ cd /config/auth/EasyRSA-v3.0.6
vyos@vyos:/config/auth/EasyRSA-v3.0.6$ ./easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /config/auth/EasyRSA-v3.0.6/pki

vyos@vyos:/config/auth/EasyRSA-v3.0.6$ ./easyrsa build-ca

Using SSL: openssl OpenSSL 1.0.1t  3 May 2016

Enter New CA Key Passphrase:
Re-Enter New CA Key Passphrase:
Generating RSA private key, 2048 bit long modulus
...............................+++
........................................+++
e is 65537 (0x10001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:VyOS fw01-server CA

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/config/auth/EasyRSA-v3.0.6/pki/ca.crt

vyos@vyos:/config/auth/EasyRSA-v3.0.6$
```

Generate DH parameters:
```terminal
./easyrsa gen-dh
```

Result:

```terminal
vyos@vyos:/config/auth/EasyRSA-v3.0.6$ ./easyrsa gen-dh

Using SSL: openssl OpenSSL 1.0.1t  3 May 2016
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
.........<truncated for readability>

DH parameters of size 2048 created at /config/auth/EasyRSA-v3.0.6/pki/dh.pem

vyos@vyos:/config/auth/EasyRSA-v3.0.6$
```

Build your server certificate:

```terminal
./easyrsa build-server-full fw01-server nopass
```

Enter your CA passphrase you've set above.

Result:

```terminal
vyos@vyos:/config/auth/EasyRSA-v3.0.6$ ./easyrsa build-server-full fw01-server nopass

Using SSL: openssl OpenSSL 1.0.1t  3 May 2016
Generating a 2048 bit RSA private key
..................................+++
..............................................+++
writing new private key to '/config/auth/EasyRSA-v3.0.6/pki/private/fw01-server.key.SRBWcXelcL'
-----
Using configuration from /config/auth/EasyRSA-v3.0.6/pki/safessl-easyrsa.cnf
Enter pass phrase for /config/auth/EasyRSA-v3.0.6/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'fw01-server'
Certificate is to be certified until Nov 28 11:43:52 2022 GMT (1080 days)

Write out database with 1 new entries
Data Base Updated
vyos@vyos:/config/auth/EasyRSA-v3.0.6$
```

Build client certificate:

```terminal
./easyrsa build-client-full fw01-client nopass
```

Result:

```terminal
vyos@vyos:/config/auth/EasyRSA-v3.0.6$ ./easyrsa build-client-full fw01-client nopass

Using SSL: openssl OpenSSL 1.0.1t  3 May 2016
Generating a 2048 bit RSA private key
....................................+++
.................+++
writing new private key to '/config/auth/EasyRSA-v3.0.6/pki/private/fw01-client.key.3NGEM3ovhq'
-----
Using configuration from /config/auth/EasyRSA-v3.0.6/pki/safessl-easyrsa.cnf
Enter pass phrase for /config/auth/EasyRSA-v3.0.6/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'fw01-client'
Certificate is to be certified until Nov 28 11:44:12 2022 GMT (1080 days)

Write out database with 1 new entries
Data Base Updated
vyos@vyos:/config/auth/EasyRSA-v3.0.6$
```

Generate ta.key:

```terminal
mkdir /config/auth/vtun0
/usr/sbin/openvpn --genkey --secret /config/auth/vtun0/ta.key
```

Result:

```terminal
vyos@fw01:/config$ mkdir /config/auth/vtun0
vyos@fw01:/config$ /usr/sbin/openvpn --genkey --secret /config/auth/vtun0/ta.key
```

Configure the VPN tunnel on your server firewall:

```terminal
set interfaces openvpn vtun0 description 'Site-to-Site VPN fw01-server'
set interfaces openvpn vtun0 encryption cipher aes256
set interfaces openvpn vtun0 keep-alive failure-count 3
set interfaces openvpn vtun0 keep-alive interval 10
set interfaces openvpn vtun0 local-port 1195
set interfaces openvpn vtun0 local-host 147.135.168.240
set interfaces openvpn vtun0 local-address 10.171.171.1
set interfaces openvpn vtun0 remote-address 10.171.171.2
set interfaces openvpn vtun0 mode site-to-site
set interfaces openvpn vtun0 persistent-tunnel
set interfaces openvpn vtun0 server push-route '192.168.200.0/24'
set interfaces openvpn vtun0 openvpn-option tls-server
set interfaces openvpn vtun0 tls ca-cert-file '/config/auth/EasyRSA-v3.0.6/pki/ca.crt'
set interfaces openvpn vtun0 tls cert-file '/config/auth/EasyRSA-v3.0.6/pki/issued/fw01-server.crt'
set interfaces openvpn vtun0 tls dh-file '/config/auth/EasyRSA-v3.0.6/pki/dh.pem'
set interfaces openvpn vtun0 tls key-file '/config/auth/EasyRSA-v3.0.6/pki/private/fw01-server.key'
set interfaces openvpn vtun0 use-lzo-compression
set zone-policy zone SITE2SITE interface 'vtun0'
```

Copy the ca.crt, dh.pem, ta.key, fw01-client.crt and fw01-client.key to your client firewall.

Configure the VPN tunnel on your client firewall (i use vtun3 here as vtun0 - vtun2 is already used on my other firewall):

```terminal
set interfaces openvpn vtun3 description 'Site-to-Site VPN fw01-client'
set interfaces openvpn vtun3 encryption aes256
set interfaces openvpn vtun3 keep-alive failure-count 3
set interfaces openvpn vtun3 keep-alive interval 10
set interfaces openvpn vtun3 mode site-to-site
set interfaces openvpn vtun3 remote-host 147.135.168.240
set interfaces openvpn vtun3 remote-port 1195
set interfaces openvpn vtun3 local-port 1195
set interfaces openvpn vtun3 local-address 10.171.171.2
set interfaces openvpn vtun3 remote-address 10.171.171.1
set interfaces openvpn vtun3 persistent-tunnel
set interfaces openvpn vtun3 openvpn-option tls-client
set interfaces openvpn vtun3 tls ca-cert-file '/config/auth/vtun3/ca.crt'
set interfaces openvpn vtun3 tls cert-file '/config/auth/vtun3/fw01-client.crt'
set interfaces openvpn vtun3 tls dh-file '/config/auth/vtun3/dh.pem'
set interfaces openvpn vtun3 tls key-file '/config/auth/vtun3/fw01-client.key'
set interfaces openvpn vtun3 use-lzo-compression
set zone-policy zone SITE2SITE interface 'vtun3'
```

If you have issues with the configuration not working, try to increase the verbosity level by adding
```terminal
set interfaces openvpn vtun3 openvpn-option 'verb 4'
```
to the configuration (remember to change to your vtunX configuration).

Allow access to your server firewall on port 1195 (udp). Also allow traffic between the firewall zones, if you use zones (i do):

```terminal
set zone-policy zone LOCAL from SITE2SITE firewall name SITE2SITE_LOCAL
set zone-policy zone SITE2SITE from LOCAL firewall name LOCAL_SITE2SITE
set firewall name LOCAL_SITE2SITE default-action accept
set firewall name SITE2SITE_LOCAL default-action accept
```

Adjust firewall rules as required.

Voila!
