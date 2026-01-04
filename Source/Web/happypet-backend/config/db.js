const sql = require('mssql');
require('dotenv').config();

// Support two styles of configuration:
// 1) Individual env vars: DB_USER, DB_PASS, DB_SERVER, DB_NAME, DB_PORT
// 2) Full connection string in env var named CONNECTION_STRING or Server
const configFromEnv = (() => {
    const connString = process.env.CONNECTION_STRING || process.env.Server || process.env.SERVER;
    if (connString) return connString;

    return {
        user: process.env.DB_USER,
        password: process.env.DB_PASS,
        server: process.env.DB_SERVER,
        database: process.env.DB_NAME,
        port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : undefined,
        options: {
            encrypt: true,
            trustServerCertificate: true
        }
    };
})();

const connectDB = async () => {
    try {
        if (typeof configFromEnv === 'string') {
            console.log(`⏳ Đang kết nối đến SQL Server bằng connection string...`);
            console.log('DEBUG raw connString length:', configFromEnv.length);
            console.log('DEBUG raw connString preview:', configFromEnv.substring(0, 240));

            // Parse semicolon-separated connection string into config object
            const raw = configFromEnv.trim();
            const cfg = { options: {} };

            // Handle leading tcp:host,port;... pattern
            let rest = raw;
            if (raw.toLowerCase().startsWith('tcp:')) {
                const firstSep = raw.indexOf(';');
                const hostPort = firstSep === -1 ? raw.substring(4) : raw.substring(4, firstSep);
                rest = firstSep === -1 ? '' : raw.substring(firstSep + 1);
                let host = hostPort;
                let port;
                if (host.includes(',')) {
                    const parts = host.split(',');
                    host = parts[0];
                    port = parseInt(parts[1]);
                }
                cfg.server = host;
                if (port) cfg.port = port;
            }

            const pairs = rest.split(';').map(p => p.trim()).filter(Boolean);
            for (const pair of pairs) {
                const idx = pair.indexOf('=');
                if (idx === -1) continue;
                const key = pair.substring(0, idx).trim().toLowerCase();
                const val = pair.substring(idx + 1).trim();

                if (key === 'server' || key === 'data source') {
                    let host = val;
                    if (host.startsWith('tcp:')) host = host.substring(4);
                    let port;
                    if (host.includes(',')) {
                        const parts = host.split(',');
                        host = parts[0];
                        port = parseInt(parts[1]);
                    }
                    cfg.server = host;
                    if (port) cfg.port = port;
                } else if (key === 'initial catalog' || key === 'database') {
                    cfg.database = val;
                } else if (key === 'user id' || key === 'uid' || key === 'user') {
                    cfg.user = val;
                } else if (key === 'password' || key === 'pwd') {
                    cfg.password = val;
                } else if (key === 'encrypt') {
                    cfg.options.encrypt = (val.toLowerCase() === 'true');
                } else if (key === 'trustservercertificate') {
                    cfg.options.trustServerCertificate = (val.toLowerCase() === 'true');
                }
            }

            // sensible defaults
            cfg.options = Object.assign({ encrypt: true, trustServerCertificate: false }, cfg.options);

            console.log('DEBUG parsed DB config:', { server: cfg.server, database: cfg.database, user: cfg.user, port: cfg.port });
            const pool = await sql.connect(cfg);
            console.log('✅ Đã kết nối SQL Server (parsed connection string) thành công!');
            return pool;
        } else {
            console.log(`⏳ Đang kết nối đến ${configFromEnv.server}...`);
            const pool = await sql.connect(configFromEnv);
            console.log('✅ Đã kết nối SQL Server thành công!');
            return pool;
        }
    } catch (err) {
        console.log('❌ Lỗi kết nối SQL:', err.message);
        throw err;
    }
};

module.exports = { connectDB, sql, config: configFromEnv };