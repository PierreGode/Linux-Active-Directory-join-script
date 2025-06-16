#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path


def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(e.output)
        sys.exit(e.returncode)


def discover_domain():
    """Attempt to discover the AD domain using realm"""
    try:
        output = run_cmd("realm discover 2>/dev/null | awk '/realm.name/ {print $2; exit}'")
        return output if output else None
    except SystemExit:
        return None


def join_domain(domain, admin_user, ou=None):
    cmd = ["realm", "join", "-v", f"--user={admin_user}"]
    if ou:
        cmd.append(f"--computer-ou={ou}")
    cmd.append(domain)
    run_cmd(" ".join(cmd))


def main():
    parser = argparse.ArgumentParser(description="Join Linux host to Active Directory")
    parser.add_argument("domain", nargs="?", help="Domain to join")
    parser.add_argument("-u", "--user", required=False, help="Admin user for the join")
    parser.add_argument("-o", "--ou", help="OU for computer object")
    parser.add_argument("--discover", action="store_true", help="Only discover domain")
    args = parser.parse_args()

    if args.discover:
        domain = discover_domain()
        if domain:
            print(domain)
        else:
            print("No domain discovered")
        return

    domain = args.domain or discover_domain()
    if not domain:
        print("Domain could not be discovered. Please specify the domain as argument.")
        sys.exit(1)

    admin_user = args.user or input("Admin user: ")
    join_domain(domain, admin_user, args.ou)
    print(f"Successfully joined {domain}")


if __name__ == "__main__":
    main()

