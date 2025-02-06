module.exports = {
    1: {
        gamedb: {
            host: '${GAMEDB_HOST}',
            port: 3306,
            user: 'root',
            password: '${GAMEDB_PASSWORD}',
            database: '${GAMEDB_DATABASE}',
        },
        logdb: {
            host: '${LOGDB_HOST}',
            port: 3306,
            user: 'root',
            password: '${LOGDB_PASSWORD}',
            database: '${LOGDB_DATABASE}',
        }
    }
}