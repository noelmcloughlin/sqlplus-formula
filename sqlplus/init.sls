# -*- coding: utf-8 -*-
# vim: ft=sls

    {%- if grains.kernel|lower in ('linux', 'darwin',) %}

include:
  - .archive
  - .config
  - .linuxenv

    {%- else %}

sqlplus-not-available-to-install:
  test.show_notification:
    - text: |
        The sqlplus package is unavailable for {{ salt['grains.get']('finger', grains.os_family) }}

    {%- endif %}
