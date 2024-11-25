CREATE DATABASE IF NOT EXISTS admin;
ALTER USER 'guillou73'@'%' IDENTIFIED WITH mysql_native
```sql
CREATE DATABASE IF NOT EXISTS admin;
ALTER USER 'guillou73'@'%' IDENTIFIED WITH mysql_native_password BY 'admin';
GRANT ALL PRIVILEGES ON admin.* TO 'guillou73'@'%';
FLUSH PRIVILEGES;
