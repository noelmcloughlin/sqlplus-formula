{% from "sqlplus/map.jinja" import sqlplus with context %}

sqlplus-create-extract-dirs:
  file.directory:
    - names:
      - '{{ sqlplus.tmpdir }}'
      - '{{ sqlplus.oracle.home }}'
  {% if grains.os not in ('Windows', 'MacOS',) %}
      - '{{ sqlplus.oracle.realhome }}'
    - user: root
    - group: root
    - mode: 755
  {% endif %}
    - clean: True
    - makedirs: True

{% for pkg in sqlplus.oracle.pkgs %}

  {% set url = sqlplus.oracle.uri ~ 'instantclient-' ~ pkg ~ '-' ~ sqlplus.arch ~ '-' ~ sqlplus.oracle.version ~ '.' ~ sqlplus.dl.suffix %}

sqlplus-extract-{{ pkg }}:
  cmd.run:
    - name: curl {{sqlplus.dl.opts}} -o '{{ sqlplus.tmpdir }}{{ pkg }}.{{sqlplus.dl.suffix}}' {{ url }}
    {% if grains['saltversioninfo'] >= [2017, 7, 0] %}
    - retry:
      attempts: {{ sqlplus.dl.retries }}
      interval: {{ sqlplus.dl.interval }}
    {% endif %}
    {%- if grains['saltversioninfo'] <= [2016, 11, 6] %}
      # Check local archive using hashstring for older Salt
      # (see https://github.com/saltstack/salt/pull/41914).
  module.run:
    - name: file.check_hash
    - path: '{{ sqlplus.tmpdir }}{{ pkg }}.{{ sqlplus.dl.suffix }}'
    - file_hash: {{ sqlplus.oracle.md5[ pkg ] }}
    - onchanges:
      - cmd: sqlplus-extract-{{ pkg }}
    - require_in:
      - archive: sqlplus-extract-{{ pkg }}
    {%- endif %}
  archive.extracted:
    - source: file://{{ sqlplus.tmpdir }}{{ pkg }}.{{sqlplus.dl.suffix}}
    - name: '{{ sqlplus.prefix }}'
    - archive_format: {{ sqlplus.dl.archive_type }}
    - trim_output: True
        {% if grains['saltversioninfo'] < [2016, 11, 0] %}
    - if_missing: '{{ sqlplus.oracle.realcmd }}'
        {% endif %}
        {% if grains['saltversioninfo'] >= [2016, 11, 0] %}
    - enforce_toplevel: False
        {% endif %}
        {%- if grains['saltversioninfo'] > [2016, 11, 6] %}
         #Check local archive using hashstring or hashurl
    - source_hash: {{ sqlplus.oracle.md5[ pkg ] }}
        {% endif %}
    - onchanges:
      - cmd: sqlplus-extract-{{ pkg }}
    - require_in:
      - file: sqlplus-extract-{{ pkg }}
  file.absent:
    - name: '{{sqlplus.tmpdir}}/{{ pkg }}.{{sqlplus.dl.suffix}}'
    - onchanges:
      - archive: sqlplus-extract-{{ pkg }}
    - require_in:
      - sqlplus-install-instantclient  
 
{% endfor %}

sqlplus-install-instantclient:
  file.absent:
    - name: {{ sqlplus.oracle.realhome }}
  cmd.run:
    - name: mv '{{ sqlplus.prefix }}instantclient_12_2' '{{ sqlplus.oracle.realhome }}'
    - require:
      - file: sqlplus-install-instantclient

