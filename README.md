# SaltConf19-NetOps2
SaltConf19 NetOps - Updating Device Firmware

## Logging into your master and router

This class employs a jump box that is preconfigured to provide access to your networking lab.  To begin, use any terminal emulator to log in to the lab jump box using the IP, username, and credentials provided during the presentation.

From the jump box, log in to your individual lab according to your piece of paper, e.g.:
`ssh Lab1-100`

## Handling user and API configuration for vEOS

`ssh ec2-user@veos2`

```
enable
configure terminal
username admin privilege 15 secret 0 SaltConf19
aaa authorization exec default local
management api http-commands
no shutdown
protocol http
end
write
exit
```

Don't forget your second router!

`ssh ec2-user@veos3`

## Staging firmware
Due to the topology of the lab environment we are going to do this the old-fashioned way, but below is how I would structure a state file to have each proxy host carry this out.
First, we'll SCP the file to the routers.

`scp /root/vEOS-lab-4.22.2.1F.swi admin@veos2://mnt/flash/vEOS-lab-4.22.2.1F.swi`

`scp /root/vEOS-lab-4.22.2.1F.swi admin@veos3://mnt/flash/vEOS-lab-4.22.2.1F.swi`

```
# scp_distribute.sls
{% import_yaml 'proxy_manifest.yaml' as proxies %}
{% for proxy in proxies %}
scp_to_{{ proxy }}:
  module.run:
    - name: scp.put
    - files: /root/vEOS-lab-4.22.2.1F.swi
    - remote_path: flash:/vEOS-lab-4.22.2.1F.swi
    - hostname: {{ proxy }}
    - username: admin
    - password: {{ pillar['admin_creds'] }}
 {% endfor %}
 ```

## Starting orchestration
Because multi-part orchestrations can touch multiple groups of targets, they occur on the Salt master and run with `salt-run`.  Our orchestration has a handful of objectives:

- Verify the identity of the staged firmware binary
- Set the boot image
- Write running-config to startup-config
- Reload the device
- Wait for the device to reboot and verify connectivity
- Perform the upgrade on the other device

!!! Please note that in its current iteration, reloading the switch is not recoverable!  If you want to continue with any further automation, comment out or replace the state segment that sends the reload command to the switch. !!!

`mkdir -p /srv/salt/eos`

`vi /srv/salt/eos/run_upgrade.sls` -- There is a lot here, you are heavily encouraged to type this out yourself

`mkdir -p /srv/salt/orch`

`vi /srv/salt/orch/upgrade_ab.sls`

## Run it (except the reboot!)
`salt-run state.orch orch.upgrade_ab`

Other things we'd want to do in a live environment:
- Retrieve machine data from pillar
- Validate against vendor-provided md5 or hardfail the entire orchestration
- Backup the running-config and/or startup-config
- Ensure configuration after reboot

- Build custom modules to set grain-based facts for more fluid management
