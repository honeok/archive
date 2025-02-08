-- 合服前都满足以下5个条件的玩家信息需要清理
-- 1)身份等级5级以下的角色
-- 2)15日内没有登录过的角色
-- 3)没有充值记录的角色
-- 4)不是公会长角色

-- 数据库A(比如1区example_game_1)和数据库B(比如2区example_game_2)进行合区，将数据库B的数据合到数据库A中，保留数据库A
-- 若B库和A库不在一个数据库实例，将数据库B还原到数据库A所在数据库实例
-- 以下脚本将gamedb1和gamedb2分别替换为1区和2区的实际数据库名

-- 开启事务
START TRANSACTION;

--   ↓ 必须 --
use example_game_1;
-- 设定数据库B的数据库名
SET @db_name = 'example_game_2';  -- 将数据库B的名称赋值给变量

-- 以被合并的区服进行修改!
-- 设定数据库B中重名角色以及重名公会前缀
set @pname='S002';           -- 角色重名前缀
set @uname='S002';           -- 公会重名前缀
-- ↑ --

set @ret1=NULL;
set @ret2=NULL;
set @ret3=NULL;
set @ret4=NULL;
set @ret5=NULL;
set @ret6=NULL;
set @ret7=NULL;
set @ret8=NULL;
set @ret9=NULL;
set @ret10=NULL;
set @ret11=NULL;
set @ret12=NULL;

-- 符合删除条件的角色id
drop temporary table if exists temp1;
create temporary table temp1
(id BIGINT(20));

drop temporary table if exists temp2;
create temporary table temp2
(id BIGINT(20));

insert into temp1
select id from t_player where ifnull(title->'$.id', 0) <= 5 and ifnull(pay->'$.total', 0) = 0 and datediff(now(), from_unixtime(logout_time)) >= 15 and id not in(select leader_id from t_guild);
set @ret1=ROW_COUNT();

-- 使用动态SQL查询数据库B
SET @sql = CONCAT('insert into temp2 select id from ', @db_name, '.t_player where ifnull(title->\'$.id\', 0) <= 5 and ifnull(pay->\'$.total\', 0) = 0 and datediff(now(), from_unixtime(logout_time)) >= 15 and id not in(select leader_id from ', @db_name, '.t_guild)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
GET DIAGNOSTICS @ret2 = ROW_COUNT;
DEALLOCATE PREPARE stmt;

-- A库
delete from t_activity where id in (select * from temp1);
delete from t_cave where id in (select * from temp1);
delete from t_crossboss where id in (select * from temp1);
delete from t_member where member_id in (select * from temp1);
delete from t_name where id in (select * from temp1);
delete from t_personmail where receiver_id in (select * from temp1);
delete from t_personmail where expire_time < unix_timestamp(now());
delete from t_player where id in (select * from temp1);
delete from t_ticket where id in (select * from temp1);

-- 竞技场
truncate table t_gpvp;
truncate table t_pvp;
truncate table t_pvp_ladder;
-- 排行
truncate table t_rank;
truncate table t_rank_guild;
truncate table t_rank_season;
-- 队伍
truncate table t_team;

update t_player set `pvp`='{}', `rank`='{}', `gpvp`='{}', `pvp_ladder`='{}';
set @ret3=ROW_COUNT();
update t_guild set `rank_seasons`='{}';

-- B库
SET @sql = CONCAT('delete from ', @db_name, '.t_activity where id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_cave where id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_crossboss where id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_member where member_id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_name where id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_personmail where receiver_id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_personmail where expire_time < unix_timestamp(now())');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_player where id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('delete from ', @db_name, '.t_ticket where id in (select * from temp2)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('update ', @db_name, '.t_player set `pvp`=\'{}\', `rank`=\'{}\', `gpvp`=\'{}\', `pvp_ladder`=\'{}\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
GET DIAGNOSTICS @ret4 = ROW_COUNT;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('update ', @db_name, '.t_guild set `rank_seasons`=\'{}\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 新建临时表temp3存放数据库B中重名角色id
drop temporary table if exists temp3;
create temporary table temp3
(a_id   BIGINT(20),
 b_id   BIGINT(20));
-- 新建临时表temp4存放数据库B中重名军团guid,名字
drop temporary table if exists temp4;
create temporary table temp4
(a_id   BIGINT(20),
 b_id   BIGINT(20));

-- 向临时表temp3中插入数据库BA中重名角色id
SET @sql = CONCAT('insert into temp3(a_id,b_id) select a.id,b.id from ', @db_name, '.t_player a inner join t_player b on a.name=b.`name` and a.name<>\'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
GET DIAGNOSTICS @ret5 = ROW_COUNT;
DEALLOCATE PREPARE stmt;

-- 向临时表temp4中插入数据库BA中重名军团id
SET @sql = CONCAT('insert into temp4 (a_id,b_id) select a.id,b.id from ', @db_name, '.t_guild a inner join t_guild b on a.name=b.`name` and a.name<>\'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
GET DIAGNOSTICS @ret6 = ROW_COUNT;
DEALLOCATE PREPARE stmt;

-- 修改数据库B中重名角色的名字
SET @sql = CONCAT('update ', @db_name, '.t_player set `name`=CONCAT(@pname,zone_id,\'.\',`name`), grocery = json_remove(grocery, \'$.rename_times\') where id in (select a_id from temp3)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
GET DIAGNOSTICS @ret7 = ROW_COUNT;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('update ', @db_name, '.t_name set `name`=CONCAT(@pname,zone_id,\'.\',`name`) where id in (select a_id from temp3)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
GET DIAGNOSTICS @ret8 = ROW_COUNT;
DEALLOCATE PREPARE stmt;

-- 修改数据库B中重名军团的名字
SET @sql = CONCAT('update ', @db_name, '.t_guild set rename_times = 1 where rename_times = 0;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sql = CONCAT('update ', @db_name, '.t_guild set `name`=CONCAT(@uname,zone_id,\'.\',`name`), rename_times=0 where id in (select a_id from temp4)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
GET DIAGNOSTICS @ret9 = ROW_COUNT;
DEALLOCATE PREPARE stmt;

-- 修改数据库A中重名角色的名字
update t_player set `name`=CONCAT(@pname,zone_id,'.',`name`), grocery = json_remove(grocery, '$.rename_times') where id in (select b_id from temp3);
set @ret10=ROW_COUNT();
update t_name set `name`=CONCAT(@pname,zone_id,'.',`name`) where id in (select b_id from temp3);
set @ret11=ROW_COUNT();
-- 修改数据库A中重名军团的名字
update t_guild set rename_times = 1 where rename_times = 0;
update t_guild set `name`=CONCAT(@uname,zone_id,'.',`name`), rename_times=0 where id in (select b_id from temp4);
set @ret12=ROW_COUNT();

-- 数据合并
-- 角色
SET @sql = CONCAT('set @columns = (select group_concat(\'`\', column_name, \'`\' separator \', \') from information_schema.columns where table_schema=\'', @db_name, '\' and table_name=\'t_player\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('set @sql = concat(\'insert into t_player (\', @columns, \') select \', @columns, \' from ', @db_name, '.t_player\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 角色名
SET @sql = CONCAT('set @columns = (select group_concat(\'`\', column_name, \'`\' separator \', \') from information_schema.columns where table_schema=\'', @db_name, '\' and table_name=\'t_name\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('set @sql = concat(\'insert into t_name (\', @columns, \') select \', @columns, \' from ', @db_name, '.t_name\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 活动
SET @sql = CONCAT('set @columns = (select group_concat(\'`\', column_name, \'`\' separator \', \') from information_schema.columns where table_schema=\'', @db_name, '\' and table_name=\'t_activity\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('set @sql = concat(\'insert into t_activity (\', @columns, \') select \', @columns, \' from ', @db_name, '.t_activity\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 个人邮件
SET @sql = CONCAT('set @columns = (select group_concat(\'`\', column_name, \'`\' separator \', \') from information_schema.columns where table_schema=\'', @db_name, '\' and table_name=\'t_personmail\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('set @sql = concat(\'insert into t_personmail (\', @columns, \') select \', @columns, \' from ', @db_name, '.t_personmail\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 军团
SET @sql = CONCAT('set @columns = (select group_concat(\'`\', column_name, \'`\' separator \', \') from information_schema.columns where table_schema=\'', @db_name, '\' and table_name=\'t_guild\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('set @sql = concat(\'insert into t_guild (\', @columns, \') select \', @columns, \' from ', @db_name, '.t_guild\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 加军团cd
SET @sql = CONCAT('set @columns = (select group_concat(\'`\', column_name, \'`\' separator \', \') from information_schema.columns where table_schema=\'', @db_name, '\' and table_name=\'t_member\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('set @sql = concat(\'insert into t_member (\', @columns, \') select \', @columns, \' from ', @db_name, '.t_member\')');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 删除临时表
drop temporary table temp1;
drop temporary table temp2;
drop temporary table temp3;
drop temporary table temp4;

-- 提交事务
COMMIT;

-- 输出结果
select 'result:', @ret1,@ret2,@ret3,@ret4,@ret5,@ret6,@ret7,@ret8,@ret9,@ret10,@ret11,@ret12;