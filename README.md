# Linux-Active-Directory-join-script By Pierre Gode 2017-2026

[![GitHub stars](https://img.shields.io/github/stars/PierreGode/Linux-Active-Directory-join-script)](https://github.com/PierreGode/Linux-Active-Directory-join-script/stargazers) [![Commits per Month](https://img.shields.io/github/commit-activity/m/PierreGode/Linux-Active-Directory-join-script)](https://github.com/PierreGode/Linux-Active-Directory-join-script/commits/main) ![Tech Stack](https://img.shields.io/badge/stack-Bash%20%7C%20Python%20%7C%20Shell-brightgreen) [![Platform](https://img.shields.io/badge/platform-Linux-blue.svg)](https://shields.io/)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/J3J2EARPK)

If you like this project please star it, that will also encourage me with updates.

Join a Linux computer or server to Active Directory with **realmd** and **sssd**, and get everything around the join configured as well: sudo rights from an AD group, home folders, short user names, cached logins, an optional SSH allow list and optional LDAPS. Answer a few questions, or run it unattended with a `readfile`.

Also see the [Wiki](https://github.com/PierreGode/Linux-Active-Directory-join-script/wiki).

## Why a script?

Joining a domain can be simple, but getting everything to work properly afterwards is harder:

- empty login prompts for new AD users
- sudo permissions for the right AD users
- cached ("mobile") accounts that can log in away from the office network
- restricting who can log in over SSH
- the extra settings sssd.conf needs

This script does all of that for you, and has been built up from many small improvements as needs have come up since 2017.

## Supported distributions

The distribution is detected from `/etc/os-release`. Derivatives that are not listed are matched by their parent distribution (`ID_LIKE`).

| Family | Distributions |
|---|---|
| Ubuntu | Ubuntu 14-26 and flavours (MATE, Kubuntu, Xubuntu...), Pop!_OS, Linux Mint, Zorin, Elementary OS |
| Debian | Debian 8-13, Raspberry Pi OS, Kali |
| RHEL / Fedora | Fedora, CentOS, RHEL, Rocky Linux, AlmaLinux, Oracle Linux |
| SUSE | openSUSE Leap / Tumbleweed, SLES |

> **Kali:** sssd is currently missing from Kali's repositories. The script detects this and offers to install sssd from Debian's repository instead (only sssd is installed from there).

## Quick start

```bash
sudo apt-get install git -y        # or: sudo dnf install git / sudo zypper install git
git clone https://github.com/PierreGode/Linux-Active-Directory-join-script.git
cd Linux-Active-Directory-join-script
sudo ./ADconnection.sh             # or: sudo sh ADconnection.sh
```

Pick **1) Join to AD** in the menu and answer the questions. Run the script from the repository folder, because `readfile` is read from the current directory.

To update to the latest version, run `git pull` in the `Linux-Active-Directory-join-script` folder.

## Before you start

1. **Hostname.** The computer object in AD is named after the hostname, for example `linuxcomputer`. Set it before joining (`/etc/hostname` and `/etc/hosts`) and reboot. AD computer names are max 15 characters, so a longer hostname is shortened (`kali-raspberrypi` becomes `KALI-RASPBERRYP`).
2. **DNS.** The client must use your domain controllers as DNS servers, so that `host -t SRV _ldap._tcp.yourdomain.com` answers. Having `search yourdomain.com` in `/etc/resolv.conf` also lets the script find the domain by itself.
3. **Time.** Kerberos needs the clock within 5 minutes of the domain controllers. The script keeps the time sync service you already run, or installs one.
4. **Sudo group.** If AD users should get sudo, create an AD group named after the hostname plus `sudoers`, for example `linuxcomputersudoers`, and add the users to it.
5. **Admin account.** You need an AD account that is allowed to join computers to the domain.

## How the domain is found

1. `realm discover`, which finds a domain announced by DHCP.
2. The DNS search and domain names from `/etc/resolv.conf`, systemd-resolved and NetworkManager, and the host's own DNS domain (`hostname -d`), including their parent domains (`clients.corp.example.com`, then `corp.example.com`).
3. The first one that realmd confirms as an Active Directory realm is offered to you, and you can accept it or type another one.

If nothing is found you are asked to type the domain. To skip discovery, set `DOMAIN` in `readfile`.

## What the script configures

- **Join:** realmd/adcli join, with the computer object named after the hostname in the default `CN=Computers` container, or in the OU you set with `OUSPECIFIED` in `readfile` or the `-o` option.
- **Users:** short user names (`user`, not `user@domain.com`), home folders `/home/user` created at first login (`pam_mkhomedir`, umask 0077), and cached credentials so users can log in away from the office network.
- **Sudo:** `/etc/sudoers.d/sudoers` gets `administrator` and `%HOSTNAMEsudoers` (plus domain admins in `/etc/sudoers.d/domain_admins`), with or without a password prompt, as you choose. Sudo rules are read from files only (`sudoers: files` in `/etc/nsswitch.conf`).
- **SSH allow list (optional):** only listed groups and users can log in (`pam_listfile` with `/etc/ssh/login.group.allowed`). The script adds `HOSTNAMEsudoers`, domain admins, root and the local login users.
- **LDAPS / SASL (optional):** sssd can use a signed and encrypted LDAP connection (`ldap_uri` and `ldap_tls_cacert`) to your domain controller. Put your company root CA (`.cer`) in `/usr/share/ca-certificates/root/` first. See the wiki for more.
- **Ubuntu desktops (LightDM):** the login screen lets you type a user name, and the guest login is turned off.

> **Warning:** with the SSH allow list, any user who is not in the file can no longer log in, locally or over SSH. Check that `/etc/ssh/login.group.allowed` contains your own local user before you reboot.

If you choose not to give sudo rights, you don't need the `HOSTNAMEsudoers` group in AD: all domain users can log in, without sudo. This option cannot be combined with **yes** on the SSH allow list.

## Menu

| Option | What it does |
|---|---|
| 1) Join to AD | Installs the packages, finds the domain, joins and configures the computer |
| 2) Check for errors | Checks that the realm is configured, the sudoers file and the PAM configuration |
| 3) Search with ldap | Searches AD with ldapsearch for this computer and for a name you type (set `BASE` and `URI` in `/etc/ldap/ldap.conf` first) |
| 4) Reauthenticate | Leaves the domain and joins again (a fix for clients that lose users) |
| 5) Leave Domain | Leaves the domain |

## Command line options

```text
sudo ./ADconnection.sh [option]
```

| Option | What it does |
|---|---|
| `--help` | Shows the help text |
| `-d` | Ubuntu debug mode: opens two terminals that follow the journal while you join (needs a desktop, does not work over SSH) |
| `-j ADadmin domain` | Simple direct join with `realm join`, without the extra configuration |
| `-l` | Runs the menu and writes the output to `adconnection.log` |
| `-s` | Shows the domain the script would discover |
| `-o "OU=Clients,OU=Computers,DC=domain,DC=com"` | Joins with the computer object in that OU (Ubuntu) |
| `-u` / `-u user` | Looks up the domain users on this computer, or one user, to check that AD users can be found |
| `-p` | Creates an encrypted admin password for `readfile` (see below) |

## Unattended join with readfile

Set the values in `readfile` to skip the questions. `null` means the script asks you.

| Setting | Value |
|---|---|
| `DOMAIN` | Domain to join, for example `domain.com` (`null` discovers it) |
| `OUSPECIFIED` | OU for the computer object, for example `--computer-ou=OU=Clients,OU=Computers,DC=domain,DC=com` (Ubuntu, Zorin) |
| `ADADMIN` | AD account used for the join |
| `LOCALADMIN` | Local account to keep in the SSH allow list |
| `SUDOERS` | `yes` / `no`: give `HOSTNAMEsudoers` sudo rights |
| `DISSPROMT` | `yes` / `no`: sudo without password prompt |
| `SSHSECURE` | `yes` / `no`: enable the SSH allow list |
| `USESASL` | `yes` / `no`: use LDAPS (SASL) |
| `LDAPS` | Your domain controller, for example `ldaps://dc01.domain.com:636` |
| `CACERT` | Full path to your root CA, for example `/usr/share/ca-certificates/root/myCA.cer` |
| `ENCRYPTEDPASSWD` | `yes` / `no`: use the encrypted admin password (Ubuntu, Zorin) |

### Encrypted admin password

For those who don't want to use one-time passwords, `sudo ./ADconnection.sh -p` asks for the admin password and creates `private_key.pem`, `public_key.pem` and `encrypted.dat`. Set `ENCRYPTEDPASSWD = yes` in `readfile`. Store the private key in a safe place, and only put the files in the `Linux-Active-Directory-join-script` folder during the join.

## After joining

Reboot and wait a few minutes for AD to sync. Then log in with your AD user name only, for example `user`: no `@domain.com` or `DOMAIN\user` is needed.

To check that it works, from the local admin account:

```bash
realm list                                 # shows the joined domain
id user                                    # the AD user and its groups
id user | grep -i linuxcomputersudoers     # the user is in the sudo group
```

You can also run the script again and pick **2) Check for errors**.

## Troubleshooting

**After reboot I can't log in at all (local or AD).**
This is most likely the SSH allow list. Make sure the right users are in `/etc/ssh/login.group.allowed`, or run the script again and answer no to the SSH allow list.

**I rebooted but still can't log in with my AD user.**
Wait 5 minutes for AD to sync, and check that the computer object exists in AD. Log in with your local account and run `sudo systemctl restart sssd`, then `id yourADusername`. If you see the user and its AD groups, it works. If you use an AD group for sudo, check it with `id yourADusername | grep -i linuxcomputersudoers`.

**The script can't find my domain.**
Check that the client uses the domain controllers as DNS servers and that `host -t SRV _ldap._tcp.yourdomain.com` answers. Adding `search yourdomain.com` to the DNS settings also helps, or set `DOMAIN` in `readfile`.

**I got the wrong hostname, or it was not created as a computer object in AD.**
Log in with the local admin, change the hostname in `/etc/hostname` and `/etc/hosts`, and update `/etc/sudoers.d/sudoers` and `/etc/ssh/login.group.allowed` (if configured) so they match the AD group. Then run `sudo realm leave domain.com`, reboot and join again with the script; it will not overwrite files that are already configured. If the computer object exists in AD but you want to replace it, delete it and join again with the same hostname. Reboot and wait 5 minutes before logging in.

**I changed my password in AD, but Linux still wants the old one.**
The new password is read from AD when you are on the office network. Your user is cached at the first login, so you can log in when you are not connected to the office network. If the computer doesn't pick up the new password on the office network, run `sudo systemctl restart sssd`, log out and log in with the new password. To change your AD password from Linux, use the user settings on the desktop (Ubuntu: Settings > Users > Password) or `passwd`.

**I am in the sudoers group, but programs still ask for an administrator.**
Members of the sudoers group are sudo users, but with a standard account. To give a user full administrator rights, run `sudo usermod -a -G sudo user`.

**Slow logins or slow sudo.**
The script adds cache settings to sssd to prevent hangs, slow logins and slow replies from sudo with a slow domain controller. These were added in 2017/11, so if your join is older than that, do a rejoin.

### Several domain controllers

Make sure DNS works so that sssd can find the LDAP servers. If you use several domain controllers or have a backup domain controller, see this sssd.conf example:

```ini
[sssd]
services = nss, pam
config_file_version = 2
domains = ad.example.com

[domain/ad.example.com]
id_provider = ad
auth_provider = ad
access_provider = ad
chpass_provider = ad
ad_server = dc1.ad.example.com
ad_backup_server = dc2.ad.example.com
filter_users = root at ad.example.com
filter_groups = root at ad.example.com
ldap_id_mapping = false
dyndns_update = true
dyndns_update_ptr = false
enumerate = true
subdomain_enumerate = all
cache_credentials = true
```
