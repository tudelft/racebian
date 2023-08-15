# Debugging / Flashing an SWD-capable microcontroller via the Pi

Wiring: 
```
SWCLK -- Broadcom GPIO25
SWDIO -- Broadcom GPIO24
RESET -- not used
GND   -- any
VCC   -- any 3V3 (for STM32 at least, I think)
```

## Setting the target chip
Only needs to be done one-time unless chip changes. 

Get list of available targets:
```shell
ssh pi@10.0.0.1 ls -lah /usr/share/openocd/scripts/target/stm32*.cfg
```

Point the config file to a specific chip:
```shell
ssh pi@10.0.0.1 sudo ln -sf /usr/share/openocd/scripts/target/stm32h7x.cfg /opt/openocd/chip.cfg
```

## Start debugging
Connect wires, then run:

```shell
ssh pi@10.0.0.1 sudo systemctl start openocd.service
```

Now, on your local machine, you can connect a local instance of `gdb-multilib`:
```shell
gdb-multilib
(gdb) target extended-remote 10.0.0.1:3333
(gdb) monitor reset
```

You will need these prerequisites:
```shell
apt install binutils-multilib gdb-multilib
```

### integration in VSCode

Install the `Cortex-Debug` extension.

Use this `.vscode/launch.json` configuration (change executable of course, and compile with debug symbols on and optimisations off):
```json
{
    // Use IntelliSense to learn about possible Node.js debug attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "cwd": "${workspaceRoot}",
            "executable": "obj/main/betaflight_STM32H743.elf",
            "name": "Cortex OpenOCD",
            "request": "launch",
            "type": "cortex-debug",
            "servertype": "external",
            "gdbTarget": "10.0.0.1:3333",
            "runToEntryPoint": "main",
            "showDevDebugOutput": "none",
            "objdumpPath": "/usr/bin/objdump"
        }
    ]
}
```

Add this line to settings `.vscode/launch.json` configuration:
```json
    "cortex-debug.gdbPath.linux": "/usr/bin/gdb-multiarch"
```

## Flashing

1. Get an `.elf` binary onto the pi, using e.g. `sftp` or `rsync`
2. Make sure the debugger is stopped `ssh pi@10.0.0.1 sudo systemctl stop openocd.service`
3. Flash `ssh pi@10.0.0.1 'openocd -f /opt/openocd/openocd.cfg -c "program betaflight_STM32H743.elf verify reset exit"'`
