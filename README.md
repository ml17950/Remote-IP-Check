# Remote-IP-Check

A small FreeBASIC console tool for Windows that watches your external IP address.

At a configurable interval it queries an HTTPS URL that returns your public IP as plain text. It then:

- logs and runs `Remote-IP-Check.changed.bat` when the IP differs from the last check (`old IP -> new IP`),
- logs and runs `Remote-IP-Check.offline.bat` when the system goes offline,
- logs and runs `Remote-IP-Check.online.bat` when the system is back online.

All files live next to the executable.

## Files

| File | Purpose |
|------|---------|
| `Remote-IP-Check.exe` | the tool |
| `Remote-IP-Check.ini` | configuration and state (created with defaults on first start) |
| `Remote-IP-Check.log` | log file (appended) |
| `Remote-IP-Check.changed.bat` | run when the IP changed; receives `%1` = last IP, `%2` = this (new) IP |
| `Remote-IP-Check.offline.bat` | run when the system went offline; receives `%1` = computer name |
| `Remote-IP-Check.online.bat` | run when the system is online again; receives `%1` = computer name |

The batch scripts are optional; a missing script is logged and skipped.

## Batch scripts

The scripts are started with `cmd /c` from the directory of the executable and the tool waits until they finish. Arguments:

| Script | `%1` | `%2` |
|--------|------|------|
| `Remote-IP-Check.changed.bat` | last IP (before the change) | this IP (new) |
| `Remote-IP-Check.offline.bat` | computer name (`%COMPUTERNAME%`) | – |
| `Remote-IP-Check.online.bat` | computer name (`%COMPUTERNAME%`) | – |

### Examples

`Remote-IP-Check.changed.bat`

```bat
@echo off
echo IP of %COMPUTERNAME% changed from %1 to %2
rem e.g. update a DNS record, send a mail, ...
```

`Remote-IP-Check.offline.bat`

```bat
@echo off
echo %1 is offline
rem e.g. switch to a fallback connection
```

`Remote-IP-Check.online.bat`

```bat
@echo off
echo %1 is online again
rem e.g. switch back to the primary connection
```

## Configuration

```ini
[config]
check_url=https://api.ipify.org
check_interval=60
check_counter=3

[status]
last_ip=
this_ip=
status=online
```

### `[config]`

- `check_url` – HTTPS URL returning the external IP as plain text.
- `check_interval` – seconds between two checks.
- `check_counter` – number of consecutive failed checks before the system is considered offline (avoids false alarms on a single timeout).

The config is re-read every cycle, so changes apply without restarting.

### `[status]`

Maintained by the tool and persisted across restarts:

- `this_ip` – the current known external IP.
- `last_ip` – the IP before the most recent change.
- `status` – `online` or `offline`.

## Behavior

- First run (no `this_ip` yet): the IP is logged as initial IP and stored; no script is run.
- If the connection returns after being offline, `online.bat` runs first, then `changed.bat` if the IP also changed.
- The last known IP is kept while offline.

## Log example

```
2026-10-14 10:55:01  Remote-IP-Check started
2026-10-14 10:55:02  initial IP: 203.0.113.5
2026-10-14 11:20:02  IP changed: 203.0.113.5 -> 203.0.113.9
2026-10-14 11:20:02  running script: C:\Tools\Remote-IP-Check.changed.bat
2026-10-14 12:01:10  system is offline (3 failed checks)
2026-10-14 12:05:10  system is online again
```

## Build

Requires [FreeBASIC](https://www.freebasic.net/) on Windows:

```
fbc -s console Remote-IP-Check.bas Remote-IP-Check.rc
```

Uses WinINet for HTTPS, so no extra libraries or certificates need to be installed.

## License

See [LICENSE](LICENSE).
