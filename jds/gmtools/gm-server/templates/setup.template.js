module.exports = {
    port: 3000,
    timezone: '+08:00',
    jwt_secret: 'p8_token20240410',
    gmdb: {
        host: '${GMDB_HOST}',
        database: '${GMDB_DATABASE}',
        user: 'root',
        password: '${GMDB_PASSWORD}',
        port: 3306
    },
    reportdb: {
        host: '${REPORTDB_HOST}',
        database: '${REPORTDB_DATABASE}',
        user: 'root',
        password: '${REPORTDB_PASSWORD}',
        port: 3306
    },
    accountdb: {
        host: '${ACCOUNTDB_HOST}',
        database: '${ACCOUNTDB_DATABASE}',
        user: 'root',
        password: '${ACCOUNTDB_PASSWORD}',
        port: 3306
    },
    centerdb: {
        host: '${CENTERDB_HOST}',
        database: '${CENTERDB_DATABASE}',
        user: 'root',
        password: '${CENTERDB_PASSWORD}',
        port: 3306
    },
    gmgame: {
        host: '${GMGAME_HOST}',
        port: '${GMGAME_PORT}'
    }
}