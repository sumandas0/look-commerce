{{ config(
    partition_by={"field": "session_date", "data_type": "date"},
    cluster_by=["traffic_source", "browser", "deepest_funnel_stage"]
) }}

select * from {{ ref('int_sessions') }}

