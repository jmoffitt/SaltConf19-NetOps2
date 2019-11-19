# Log md5 in the job run for diagnostic purposes, or a target for further
# automation to verify image before applying
check_md5:
  module.run:
    - name: pyeapi.run_commands
    - commands:
      - verify /md5 flash:/vEOS-lab-4.22.2.1F.swi

# Configure boot image
set_system_boot:
  module.run:
    - name: pyeapi.config
    - commands:
      - boot system flash:/vEOS-lab-4.22.2.1F.swi
    - require:
      - module: check_md5

write_to_startup_config:
  module.run:
    - name: pyeapi.run_commands
    - commands:
      - write
    - require:
      - module: set_system_boot

system_reload:
  module.run:
    - name: pyeapi.run_commands
    - commands:
      - reload force
    - require:
      - write_to_startup_config
