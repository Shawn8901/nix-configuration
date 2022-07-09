#!/usr/bin/env python3

###############################################################################
#
# Copied from Mic92s tasks.py
# https://github.com/Mic92/dotfiles/blob/master/tasks.py
#
###############################################################################

from invoke import task

import sys, os, subprocess
from deploy_nixos import DeployHost, DeployGroup, parse_hosts, HostKeyCheck


RSYNC_EXCLUDES = [".git", ".github", ".gitignore", ".direnv", "result"]
ALL_HOSTS = DeployGroup([DeployHost("localhost"), DeployHost("tank"),  DeployHost("shelter.pointjig.de"),])

if "flake.nix" not in os.listdir(os.getcwd()):
    print("No flake.nix found, likely we are in a subdirectory.")
    sys.exit(1)

def parse_host_arg(hosts:str):
    if hosts == "all":
        return ALL_HOSTS
    return parse_hosts(hosts)


def wait_for_reboot(h: DeployHost):
    print(f"Wait for {h.host} to shutdown", end="")
    sys.stdout.flush()
    wait_for_port(h.host, h.port, shutdown=True)
    print("")

    print(f"Wait for {h.host} to start", end="")
    sys.stdout.flush()
    wait_for_port(h.host, h.port)
    print("")

def wait_for_port(host: str, port: int, shutdown: bool = False) -> None:
    import socket, time

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

@task
def boot(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)
    def run(h: DeployHost) -> None:
        flake_path = "/etc/nixos"
        flake_attr = h.meta.get("flake_attr")
        if flake_attr:
            flake_path += "#" + flake_attr
        target_host = h.meta.get("target_host", "localhost")

        h.run_local(
            f"rsync {' --exclude '.join([''] + RSYNC_EXCLUDES)} -vaF --delete -e ssh . {h.user}@{h.host}:/etc/nixos"
        )
        h.run(
            f"nixos-rebuild boot --build-host localhost --target-host {target_host} --flake $(realpath {flake_path})"
        )

    g.run_function(run)

@task
def deploy(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)

    def run(h: DeployHost) -> None:
        flake_path = "/etc/nixos"
        flake_attr = h.meta.get("flake_attr")
        if flake_attr:
            flake_path += "#" + flake_attr
        target_host = h.meta.get("target_host", "localhost")

        h.run_local(
            f"rsync {' --exclude '.join([''] + RSYNC_EXCLUDES)} -vaF --delete -e ssh . {h.user}@{h.host}:/etc/nixos"
        )

        h.run(
            f"nixos-rebuild switch --build-host localhost --target-host {target_host} --flake $(realpath {flake_path})"
        )
        h.run("ls -v /nix/var/nix/profiles | tail -n 2 | awk '{print \"/nix/var/nix/profiles/\" $$0}' - | xargs nvd diff")

    g.run_function(run)


@task
def build(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)

    def run(h: DeployHost) -> None:
        flake_path = "/etc/nixos"
        flake_attr = h.meta.get("flake_attr")
        if flake_attr:
            flake_path += "#" + flake_attr
        target_host = h.meta.get("target_host", "localhost")

        h.run_local(
            f"rsync {' --exclude '.join([''] + RSYNC_EXCLUDES)} -vaF --delete -e ssh . {h.user}@{h.host}:/etc/nixos"
        )
        h.run(
            f"nixos-rebuild build --build-host localhost --target-host {target_host} --flake $(realpath {flake_path})"
        )
        h.run(f"nvd diff $(ls --reverse -v /nix/var/nix/profiles | head --lines=1 | awk '{{print \"/nix/var/nix/profiles/\" $$0}}' -) ~/result")

    g.run_function(run)

@task
def test(_, hosts="localhost"):
    g: DeployGroup = parse_host_arg(hosts)
    def run(h: DeployHost) -> None:
        flake_path = "/etc/nixos"
        flake_attr = h.meta.get("flake_attr")
        if flake_attr:
            flake_path += "#" + flake_attr
        target_host = h.meta.get("target_host", "localhost")

        h.run_local(
            f"rsync {' --exclude '.join([''] + RSYNC_EXCLUDES)} -vaF --delete -e ssh . {h.user}@{h.host}:/etc/nixos"
        )
        h.run(
            f"nixos-rebuild test --build-host localhost --target-host {target_host} --flake $(realpath {flake_path})"
        )

    g.run_function(run)

@task
def add_github_user(_, hosts="", github_user="shawn8901"):
    def add_user(h: DeployHost) -> None:
        h.run(f"mkdir -m700 /root/.ssh")
        out = h.run_local(
            f"curl https://github.com/{github_user}.keys", stdout=subprocess.PIPE
        )
        h.run(
            f"echo '{out.stdout}' >> /root/.ssh/authorized_keys && chmod 700 /root/.ssh/authorized_keys"
        )

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

    def run(h: DeployHost) -> None:
        h.run("find /nix/var/nix/gcroots/auto -type s -delete")
        h.run("systemctl restart nix-gc")
        h.run("nix-collect-garbage -d")
        h.run("nix store optimise")

    g.run_function(run)

@task
def flake_update(_):
    d = DeployHost("localhost")
    d.run_local("nix flake update")

@task
def check(_):
    d = DeployHost("localhost")
    d.run_local("nix flake check")
