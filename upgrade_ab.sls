{% set proxies = ['pyeapi1', 'pyeapi2'] %}
{% for proxy in proxies %}
upgrade_{{ proxy }}:
  salt.state:
    - tgt: {{ proxy }}
    - sls: eos.run_upgrade
    - check_cmd:
      - 'until ping -c 1 veos2; do sleep 5 && ((x++)); if [[ x -eq 30 ]]; then break; fi; done'
{% endfor %}
