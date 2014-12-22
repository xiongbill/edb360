@@edb360_0g_tkprof.sql
DEF section_name = 'Security';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF title = 'Users';
DEF main_table = 'DBA_USERS';
BEGIN
  :sql_text := '
-- incarnation from health_check_4.4 (Jon Adams and Jack Agustin)
SELECT /*+ &&top_level_hints. */ 
       *
  FROM dba_users
 ORDER BY username
';
END;
/
@@edb360_9a_pre_one.sql

DEF title = 'Profiles';
DEF main_table = 'DBA_PROFILES';
BEGIN
  :sql_text := '
-- incarnation from health_check_4.4 (Jon Adams and Jack Agustin)
SELECT /*+ &&top_level_hints. */ 
       *
  FROM dba_profiles
 ORDER BY profile
';
END;
/
@@edb360_9a_pre_one.sql

DEF title = 'Default Object Auditing Options';
DEF main_table = 'ALL_DEF_AUDIT_OPTS';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */ 
       *
  FROM all_def_audit_opts
';
END;
/
@@edb360_9a_pre_one.sql

DEF title = 'Object Auditing Options';
DEF main_table = 'DBA_OBJ_AUDIT_OPTS';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */ 
       *
  FROM dba_obj_audit_opts
 ORDER BY
       1, 2
';
END;
/
@@edb360_9a_pre_one.sql

DEF title = 'Statement Auditing Options';
DEF main_table = 'DBA_STMT_AUDIT_OPTS';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */ 
       *
  FROM dba_stmt_audit_opts
 ORDER BY
       1 NULLS FIRST, 2 NULLS FIRST
';
END;
/
@@edb360_9a_pre_one.sql

DEF title = 'System Privileges Auditing Options';
DEF main_table = 'DBA_PRIV_AUDIT_OPTS';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */ 
       *
  FROM dba_priv_audit_opts
 ORDER BY
       1 NULLS FIRST, 2 NULLS FIRST
';
END;
/
@@edb360_9a_pre_one.sql

DEF title = 'Users With Sensitive Roles Granted';
DEF main_table = 'DBA_ROLE_PRIVS';
BEGIN
  :sql_text := '
-- incarnation from health_check_4.4 (Jon Adams and Jack Agustin)
SELECT /*+ &&top_level_hints. */
       * from dba_role_privs
where (granted_role in 
(''AQ_ADMINISTRATOR_ROLE'',''DELETE_CATALOG_ROLE'',''DBA'',''DM_CATALOG_ROLE'',''EXECUTE_CATALOG_ROLE'',
''EXP_FULL_DATABASE'',''GATHER_SYSTEM_STATISTICS'',''HS_ADMIN_ROLE'',''IMP_FULL_DATABASE'',
   ''JAVASYSPRIV'',''JAVA_ADMIN'',''JAVA_DEPLOY'',''LOGSTDBY_ADMINISTRATOR'',
   ''OEM_MONITOR'',''OLAP_DBA'',''RECOVERY_CATALOG_OWNER'',''SCHEDULER_ADMIN'',
   ''SELECT_CATALOG_ROLE'',''WM_ADMIN_ROLE'',''XDBADMIN'',''RESOURCE'')
    or granted_role like ''%ANY%'')
   and grantee not in &&exclusion_list.
   and grantee not in &&exclusion_list2.
order by grantee, granted_role
';
END;
/
@@edb360_9a_pre_one.sql

DEF title = 'Users With Inappropriate Tablespaces Granted';
DEF main_table = 'DBA_USERS';
BEGIN
  :sql_text := '
-- incarnation from health_check_4.4 (Jon Adams and Jack Agustin)
SELECT /*+ &&top_level_hints. */
       * from dba_users
where (default_tablespace in (''SYSAUX'',''SYSTEM'') or
temporary_tablespace not in
   (select tablespace_name
   from dba_tablespaces
   where contents = ''TEMPORARY''))
and username not in &&exclusion_list.
and username not in &&exclusion_list2.
order by username
';
END;
/
@@edb360_9a_pre_one.sql

