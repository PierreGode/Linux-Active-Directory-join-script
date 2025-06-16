#!/usr/bin/env python3
"""Simple Tkinter GUI to join a Linux host to Active Directory."""
import subprocess
import tkinter as tk
from tkinter import messagebox


def run_cmd(cmd):
    """Run a shell command and return output and exit code."""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode


def discover_domain():
    """Try to auto-discover the domain using realm."""
    out, _ = run_cmd("realm discover 2>/dev/null | awk '/realm.name/ {print $2; exit}'")
    return out


def join_domain(domain, admin_user, ou):
    cmd = ["realm", "join", "-v", f"--user={admin_user}"]
    if ou:
        cmd.append(f"--computer-ou={ou}")
    cmd.append(domain)
    return run_cmd(" ".join(cmd))


def on_join():
    domain = domain_var.get().strip()
    user = user_var.get().strip()
    ou = ou_var.get().strip()
    if not domain:
        messagebox.showerror("Error", "Domain is required")
        return
    if not user:
        messagebox.showerror("Error", "Admin user is required")
        return
    output, code = join_domain(domain, user, ou)
    if code == 0:
        messagebox.showinfo("Success", f"Successfully joined {domain}")
    else:
        messagebox.showerror("Join Failed", output or "Unknown error")


root = tk.Tk()
root.title("AD Connection")

# Variables
domain_var = tk.StringVar(value=discover_domain() or "")
user_var = tk.StringVar()
ou_var = tk.StringVar()

# Layout

tk.Label(root, text="Domain:").grid(row=0, column=0, sticky="e", padx=5, pady=5)
tk.Entry(root, textvariable=domain_var, width=40).grid(row=0, column=1, padx=5, pady=5)
tk.Label(root, text="Admin User:").grid(row=1, column=0, sticky="e", padx=5, pady=5)
tk.Entry(root, textvariable=user_var, width=40).grid(row=1, column=1, padx=5, pady=5)
tk.Label(root, text="Computer OU:").grid(row=2, column=0, sticky="e", padx=5, pady=5)
tk.Entry(root, textvariable=ou_var, width=40).grid(row=2, column=1, padx=5, pady=5)
tk.Button(root, text="Join Domain", command=on_join).grid(row=3, column=0, columnspan=2, pady=10)

root.mainloop()
