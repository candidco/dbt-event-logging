{% macro get_audit_relation() %}

    {#-
    A project's version of the generate_schema_name macro will take precedence
    over the global version
    -#}
    {%- set audit_schema=generate_schema_name('dbt_meta') -%}

    {%- set audit_table =
        api.Relation.create(
            identifier='dbt_audit_log',
            schema=audit_schema,
            type='table'
        ) -%}

    {{ return(audit_table) }}

{% endmacro %}


{% macro get_audit_schema() %}
    {% set audit_table = logging.get_audit_relation() %}
    {{ return(audit_table.include(schema=True, identifier=False)) }}
{% endmacro %}


{% macro log_audit_event(event_name, schema, relation) %}

    insert into {{ logging.get_audit_relation() }} (
        event_name,
        event_timestamp,
        event_schema,
        event_model,
        invocation_id
        )

    values (
        '{{ event_name }}',
        {{dbt_utils.current_timestamp_in_utc()}},
        {% if variable != None %}'{{ schema }}'{% else %}null::varchar(512){% endif %},
        {% if variable != None %}'{{ relation }}'{% else %}null::varchar(512){% endif %},
        '{{ invocation_id }}'
        )

{% endmacro %}


{% macro create_audit_schema() %}
    create schema if not exists {{ logging.get_audit_schema() }}
{% endmacro %}


{% macro create_audit_log_table() %}

    create table if not exists {{ logging.get_audit_relation() }}
    (
       event_name       varchar(512),
       event_timestamp  {{dbt_utils.type_timestamp()}},
       event_schema     varchar(512),
       event_model      varchar(512),
       invocation_id    varchar(512)
    )

{% endmacro %}


{% macro log_run_start_event() %}
    {{logging.log_audit_event('run started')}}
{% endmacro %}


{% macro log_run_end_event() %}
    {{logging.log_audit_event('run completed')}}; commit;
{% endmacro %}


{% macro log_model_start_event() %}
    {{logging.log_audit_event(
        'model deployment started', this.schema, this.name
        )}}
{% endmacro %}


{% macro log_model_end_event() %}
    {{logging.log_audit_event(
        'model deployment completed', this.schema, this.name
        )}}
{% endmacro %}
