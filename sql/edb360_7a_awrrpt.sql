@@edb360_0g_tkprof.sql
SET VER OFF FEED OFF SERVEROUT ON HEAD OFF PAGES 50000 LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100;
DEF section_name = 'AWR Reports';
SPO &&main_report_name..html APP;
PRO <h2 title="For max/min/med 'DB time' + 'background elapsed time' for past 4 hours, and 1, 7 and &&history_days. days (for each instance)">&&section_name.</h2>
SPO OFF;

COL hh_mm_ss NEW_V hh_mm_ss NOPRI FOR A8;
SPO 9991_&&common_prefix._awr_driver.sql;
PRO VAR inst_num VARCHAR2(1023);;
DECLARE
  l_standard_filename VARCHAR2(32767);
  l_spool_filename VARCHAR2(32767);
  l_one_spool_filename VARCHAR2(32767);
  l_instances NUMBER;
  l_begin_date VARCHAR2(14);
  l_end_date VARCHAR2(14);
  PROCEDURE put_line(p_line IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_line);
  END put_line;
  PROCEDURE update_log(p_module IN VARCHAR2) IS
  BEGIN
        put_line('COL hh_mm_ss NEW_V hh_mm_ss NOPRI FOR A8;');
		put_line('SELECT TO_CHAR(SYSDATE, ''HH24:MI:SS'') hh_mm_ss FROM DUAL;');
		put_line('-- update log');
		put_line('SPO &&edb360_log..txt APP;');
        put_line('SET TERM ON;');
		put_line('PRO '||CHR(38)||chr(38)||'hh_mm_ss. col:&&column_number.of&&max_col_number. '||p_module);
        put_line('SET TERM OFF;');
		put_line('SPO OFF;');
  END update_log;
BEGIN
  SELECT COUNT(*) INTO l_instances FROM gv$instance;
  -- two reports per instance
  FOR i IN (SELECT instance_number
              FROM gv$instance
             WHERE '&&diagnostics_pack.' = 'Y'
             ORDER BY
                   instance_number)
  LOOP
    FOR j IN (WITH
              expensive2 AS (
              SELECT h1.dbid, h1.snap_id bid, h2.snap_id eid,
                     CAST(s2.begin_interval_time AS DATE) begin_date,
                     CAST(s2.end_interval_time AS DATE) end_date,
                     (h2.value - h1.value) value
                FROM dba_hist_sys_time_model h1,
                     dba_hist_sys_time_model h2,
                     dba_hist_snapshot s1,
                     dba_hist_snapshot s2
               WHERE h1.instance_number = i.instance_number
                 AND h1.stat_name IN ('DB time', 'background elapsed time')
                 AND h1.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
                 AND h1.dbid = &&edb360_dbid.
                 AND h2.snap_id = h1.snap_id + 1
                 AND h2.dbid = h1.dbid
                 AND h2.instance_number = h1.instance_number
                 AND h2.stat_id = h1.stat_id
                 AND h2.stat_name = h1.stat_name
                 AND h2.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
                 AND h2.dbid = &&edb360_dbid.
                 AND s1.snap_id = h1.snap_id
                 AND s1.dbid = h1.dbid
                 AND s1.instance_number = h1.instance_number
                 AND CAST(s1.end_interval_time AS DATE) BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - &&history_days. AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') -- includes all options
                 AND s1.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
                 AND s1.dbid = &&edb360_dbid.
                 AND s2.snap_id = s1.snap_id + 1
                 AND s2.dbid = s1.dbid
                 AND s2.instance_number = s1.instance_number
                 AND s2.startup_time = s1.startup_time
                 AND s2.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
                 AND s2.dbid = &&edb360_dbid.
              ),
              expensive AS (
              SELECT dbid, bid, eid, begin_date, end_date, SUM(value) value
                FROM expensive2
               GROUP BY
                     dbid, bid, eid, begin_date, end_date
              ),
              max_&&history_days.wd AS (
              SELECT MAX(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - &&history_days. AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 -- avoids selecting same twice
                 AND TO_CHAR(end_date, 'D') BETWEEN '2' AND '6' /* between Monday and Friday */
                 AND TO_CHAR(end_date, 'HH24') BETWEEN '0800' AND '1900' /* between 8AM to 7PM */
              ),
              min_&&history_days.wd AS (
              SELECT MIN(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - &&history_days. AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 -- avoids selecting same twice
                 AND TO_CHAR(end_date, 'D') BETWEEN '2' AND '6' /* between Monday and Friday */
                 AND TO_CHAR(end_date, 'HH24') BETWEEN '0800' AND '1900' /* between 8AM to 7PM */
              ),
              max_&&history_days.d AS (
              SELECT MAX(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - &&history_days. AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 -- avoids selecting same twice
                 AND value NOT IN (SELECT value FROM max_&&history_days.wd)
              ),
              med_&&history_days.d AS (
              SELECT PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - &&history_days. AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 -- avoids selecting same twice
              ),
              max_7wd AS (
              SELECT MAX(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 1 -- avoids selecting same twice
                 AND TO_CHAR(end_date, 'D') BETWEEN '2' AND '6' /* between Monday and Friday */
                 AND TO_CHAR(end_date, 'HH24') BETWEEN '0800' AND '1900' /* between 8AM to 7PM */
              ),
              min_7wd AS (
              SELECT MIN(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 1 -- avoids selecting same twice
                 AND TO_CHAR(end_date, 'D') BETWEEN '2' AND '6' /* between Monday and Friday */
                 AND TO_CHAR(end_date, 'HH24') BETWEEN '0800' AND '1900' /* between 8AM to 7PM */
              ),
              max_7d AS (
              SELECT MAX(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 1 -- avoids selecting same twice
                 AND value NOT IN (SELECT value FROM max_7wd)
              ),
              med_7d AS (
              SELECT PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 7 AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 1 -- avoids selecting same twice
              ),
              max_1d AS (
              SELECT MAX(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - 1 AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - (4 / 24) -- avoids selecting same twice
              ),
              max_4h AS (
              SELECT MAX(value) value
                FROM expensive
               WHERE end_date BETWEEN TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS') - (4 / 24) AND TO_DATE('&&tool_sysdate.', 'YYYYMMDDHH24MISS')
              )
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'max&&history_days.wd' rep, 50 ob
                FROM expensive e,
                     max_&&history_days.wd m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'min&&history_days.wd' rep, 100 ob
                FROM expensive e,
                     min_&&history_days.wd m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'max&&history_days.d' rep, 60 ob
                FROM expensive e,
                     max_&&history_days.d m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'med&&history_days.d' rep, 80 ob
                FROM expensive e,
                     med_&&history_days.d m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'max7wd' rep, 30 ob
                FROM expensive e,
                     max_7wd m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'min7wd' rep, 90 ob
                FROM expensive e,
                     min_7wd m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'max7d' rep, 40 ob
                FROM expensive e,
                     max_7d m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'med7d' rep, 70 ob
                FROM expensive e,
                     med_7d m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'max1d' rep, 20 ob
                FROM expensive e,
                     max_1d m
               WHERE m.value = e.value
               UNION
              SELECT e.dbid, e.bid, e.eid, e.begin_date, e.end_date, 'max4h' rep, 10 ob
                FROM expensive e,
                     max_4h m
               WHERE m.value = e.value
               ORDER BY 7)
    LOOP
      l_begin_date := TO_CHAR(j.begin_date, 'YYYYMMDDHH24MISS');
      l_end_date := TO_CHAR(j.end_date, 'YYYYMMDDHH24MISS');
      -- one node
      l_standard_filename := 'awrrpt_'||i.instance_number||'_'||j.bid||'_'||j.eid||'_'||j.rep;
      l_spool_filename := '&&common_prefix._'||l_standard_filename;
      put_line('COL hh_mm_ss NEW_V hh_mm_ss NOPRI FOR A8;');
      put_line('SELECT TO_CHAR(SYSDATE, ''HH24:MI:SS'') hh_mm_ss FROM DUAL;');
      put_line('-- update log');
      put_line('SPO &&edb360_log..txt APP;');
      put_line('PRO');
      put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      put_line('PRO');
      put_line('PRO '||CHR(38)||chr(38)||'hh_mm_ss. '||l_spool_filename);
      put_line('SPO OFF;');
      put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&edb360_log..txt');
      put_line('-- update main report');
      put_line('SPO &&main_report_name..html APP;');
      put_line('PRO <li title="DBMS_WORKLOAD_REPOSITORY">'||l_standard_filename||' <small><em>('||TO_CHAR(j.end_date,'DD-Mon-YY HH24:MI:SS')||')</em></small>');
      put_line('SPO OFF;');
      put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
      BEGIN
        :file_seq := :file_seq + 1;
        l_one_spool_filename := LPAD(:file_seq, 4, '0')||'_'||l_spool_filename;
        update_log(l_one_spool_filename||'.html');
        put_line('SPO '||l_one_spool_filename||'.html;');
        put_line('SELECT output FROM TABLE(DBMS_WORKLOAD_REPOSITORY.awr_report_html('||j.dbid||','||i.instance_number||','||j.bid||','||j.eid||',8));');
        put_line('SPO OFF;');
        put_line('-- update main report');
        put_line('SPO &&main_report_name..html APP;');
        put_line('PRO <a href="'||l_one_spool_filename||'.html">html</a>');
        put_line('SPO OFF;');
        put_line('-- zip');
        put_line('HOS zip -mq &&main_compressed_filename._&&file_creation_time. '||l_one_spool_filename||'.html');
        put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
      END;
      BEGIN
        :file_seq := :file_seq + 1;
        l_one_spool_filename := LPAD(:file_seq, 4, '0')||'_'||l_spool_filename;
        update_log(l_one_spool_filename||'.txt');
        put_line('SPO '||l_one_spool_filename||'.txt;');
        put_line('SELECT output FROM TABLE(DBMS_WORKLOAD_REPOSITORY.awr_report_text('||j.dbid||','||i.instance_number||','||j.bid||','||j.eid||',8));');
        put_line('SPO OFF;');
        put_line('-- update main report');
        put_line('SPO &&main_report_name..html APP;');
        put_line('PRO <a href="'||l_one_spool_filename||'.txt">text</a>');
        put_line('SPO OFF;');
        put_line('-- zip');
        put_line('HOS zip -mq &&main_compressed_filename._&&file_creation_time. '||l_one_spool_filename||'.txt');
        put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
      END;
      put_line('-- update main report');
      put_line('SPO &&main_report_name..html APP;');
      put_line('PRO </li>');
      put_line('SPO OFF;');
      put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');

      -- all nodes
      IF l_instances > 1 THEN
        l_standard_filename := 'awrrpt_rac_'||j.bid||'_'||j.eid||'_'||j.rep;
        l_spool_filename := '&&common_prefix._'||l_standard_filename;
        put_line('COL hh_mm_ss NEW_V hh_mm_ss NOPRI FOR A8;');
        put_line('SELECT TO_CHAR(SYSDATE, ''HH24:MI:SS'') hh_mm_ss FROM DUAL;');
        put_line('-- update log');
        put_line('SPO &&edb360_log..txt APP;');
        put_line('PRO');
        put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
        put_line('PRO');
        put_line('PRO '||CHR(38)||chr(38)||'hh_mm_ss. '||l_spool_filename);
        put_line('SPO OFF;');
        put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&edb360_log..txt');
        put_line('-- update main report');
        put_line('SPO &&main_report_name..html APP;');
        put_line('PRO <li title="DBMS_WORKLOAD_REPOSITORY">'||l_standard_filename||' <small><em>('||TO_CHAR(j.end_date,'DD-Mon-YY HH24:MI:SS')||')</em></small>');
        put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
        BEGIN
          :file_seq := :file_seq + 1;
          l_one_spool_filename := LPAD(:file_seq, 4, '0')||'_'||l_spool_filename;
          update_log(l_one_spool_filename||'.html');
          put_line('SPO '||l_one_spool_filename||'.html;');
          put_line('SELECT output FROM TABLE(DBMS_WORKLOAD_REPOSITORY.awr_global_report_html('||j.dbid||',:inst_num,'||j.bid||','||j.eid||',8));');
          put_line('SPO OFF;');
          put_line('-- update main report');
          put_line('SPO &&main_report_name..html APP;');
          put_line('PRO <a href="'||l_one_spool_filename||'.html">html</a>');
          put_line('SPO OFF;');
          put_line('-- zip');
          put_line('HOS zip -mq &&main_compressed_filename._&&file_creation_time. '||l_one_spool_filename||'.html');
          put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
        END; 
        BEGIN
          :file_seq := :file_seq + 1;
          l_one_spool_filename := LPAD(:file_seq, 4, '0')||'_'||l_spool_filename;
          update_log(l_one_spool_filename||'.txt');
          put_line('SPO '||l_one_spool_filename||'.txt;');
          put_line('SELECT output FROM TABLE(DBMS_WORKLOAD_REPOSITORY.awr_global_report_text('||j.dbid||',:inst_num,'||j.bid||','||j.eid||',8));');
          put_line('SPO OFF;');
          put_line('-- update main report');
          put_line('SPO &&main_report_name..html APP;');
          put_line('PRO <a href="'||l_one_spool_filename||'.txt">text</a>');
          put_line('SPO OFF;');
          put_line('-- zip');
          put_line('HOS zip -mq &&main_compressed_filename._&&file_creation_time. '||l_one_spool_filename||'.txt');
          put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
        END;
        put_line('-- update main report');
        put_line('SPO &&main_report_name..html APP;');
        put_line('PRO </li>');
        put_line('SPO OFF;');
        put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
      END IF;
    END LOOP;
  END LOOP;
END;
/
SPO OFF;
@9991_&&common_prefix._awr_driver.sql;
SET SERVEROUT OFF HEAD ON PAGES &&def_max_rows.;
HOS zip -mq &&main_compressed_filename._&&file_creation_time. 9991_&&common_prefix._awr_driver.sql