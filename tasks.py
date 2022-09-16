#!/usr/bin/env python3

###############################################################################
#
# Copied from Mic92s tasks.py
# https://github.com/Mic92/dotfiles/blob/master/tasks.py
#
###############################################################################

import enum
import os
import subprocess
import sys

from invoke import task

from deploy_nixos import DeployGroup, DeployHost, HostKeyCheck, parse_hosts

RSYNC_EXCLUDES = [".git", ".github", ".gitignore", ".direnv", "result"]
ALL_HOSTS = DeployGroup([DeployHost("pointalpha"), DeployHost("tank"),  DeployHost("shelter"),])

class NixosRebuildCommand(enum.Enum):
    BUILD = "build"
    SWITCH = "switch"
    TEST = "test"
    BOOT = "boot"


if "flake.nix" not in os.listdir(os.getcwd()):
    print("No flake.nix found, likely we are in a subdirectory.")
    sys.exit(1)

def parse_host_arg(hosts:str):
    if hosts == "all":
        return ALL_HOSTS
    return parse_hosts(hosts)


def wait_for_reboot(h: DeployHost):
    print(f"🕑 Wait for {h.host} to shutdown", end="")
    sys.stdout.flush()
    wait_for_port(h.host, h.port, shutdown=True)
    print("")

    print(f"🕑 Wait for {h.host} to start", end="")
    sys.stdout.flush()
    wait_for_port(h.host, h.port)
    print("")

def wait_for_port(host: str, port: int, shutdown: bool = False) -> None:
    import socket
    import time

    while True:
        try:
            with socket.create_connection((host, port), timeout=1):
                if shutdown:
                    time.sleep(1)
                    sys.stdout.write(".")
                    sys.stdout.flush()
                else:
                    break
        except OSError:
            if shutdown:
                break
            else:
                time.sleep(0.01)
                sys.stdout.write(".")
                sys.stdout.flush()

def sync_config(host: DeployHost):
    flake_path = "/etc/nixos"
    flake_attr = host.meta.get("flake_attr")
    if flake_attr:
        flake_path += "#" + flake_attr
    print(f"🌐 Copy configuration to {host.host}.")
    host.run_local(f"rsync {' --exclude '.join([''] + RSYNC_EXCLUDES)} -vaF --delete -e ssh . {host.user}@{host.host}:/etc/nixos")
    return flake_path

def run_command(host:DeployHost, command: NixosRebuildCommand, log:str):
    flake_path = sync_config(host)
    target_host = host.meta.get("target_host", "localhost")
    print(log)
    host.run(f"nixos-rebuild {command.value} --build-host localhost --target-host {target_host} --flake $(realpath {flake_path})")


@task
def boot(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)
    def run(h: DeployHost) -> None:
        run_command(h, NixosRebuildCommand.BOOT,"🤞 Setting configuration as boot.")

    g.run_function(run)

@task
def deploy(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)
    def run(h: DeployHost) -> None:
        run_command(h, NixosRebuildCommand.SWITCH, "🤞 Activating configuration.")
        h.run("ls -v /nix/var/nix/profiles | tail -n 2 | awk '{print \"/nix/var/nix/profiles/\" $$0}' - | xargs nvd diff")
    g.run_function(run)


@task
def build(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)
    g.run_function(lambda h: run_command(h, NixosRebuildCommand.BUILD, "🏗️ Building system."))

@task
def test(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)
    g.run_function(lambda h: run_command(h, NixosRebuildCommand.TEST,"🤞 Testing configuration."))

@task
def add_github_user(_, hosts="", github_user="shawn8901"):
    def add_user(h: DeployHost) -> None:
        h.run(f"mkdir -m700 /root/.ssh")
        out = h.run_local(f"curl https://github.com/{github_user}.keys", stdout=subprocess.PIPE)
        h.run(f"echo '{out.stdout}' >> /root/.ssh/authorized_keys && chmod 700 /root/.ssh/authorized_keys")

    g = parse_hosts(hosts, host_key_check=HostKeyCheck.NONE)
    g.run_function(add_user)


@task
def reboot(_, hosts=""):
    deploy_hosts = [DeployHost(h) for h in hosts.split(",")]
    for h in deploy_hosts:
        g = DeployGroup([h])
        g.run("systemctl reboot &")
        wait_for_reboot(h)


@task
def collect_garbage(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)
    def run(h:DeployHost):
        print(f"🧹 Collecting garbage from {h.host}")
        h.run("""
            find /nix/var/nix/gcroots/auto -type s -delete
            systemctl restart nix-gc
            nix-collect-garbage -d
            nix store optimise
        """)
    g.run_function(run)

@task
def flake_update(_):
    d = DeployHost("localhost")
    d.run_local("nix flake update")

@task
def check(_):
    d = DeployHost("localhost")
    d.run_local("nix flake check")
